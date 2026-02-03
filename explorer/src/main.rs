mod api;
mod db;
mod handlers;
mod rpc;
mod state;

use actix_cors::Cors;
use actix_web::{App, HttpServer, middleware, web};
use db::ExplorerDB;
use log::{error, info};
use rpc::NodeRpcClient;
use std::sync::Arc;
use tokio::time::{Duration, interval};

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::Builder::from_default_env()
        .filter_level(log::LevelFilter::Info)
        .init();

    info!("🌐 NetCoin Explorer starting...");

    // Explorer 데이터베이스 초기화
    let db_path = "explorer_data";
    let explorer_db = Arc::new(ExplorerDB::new(db_path).expect("Failed to open explorer database"));

    info!("💾 Explorer database initialized at {}", db_path);

    // 백그라운드에서 Node와 동기화하는 태스크
    let db_sync = explorer_db.clone();
    tokio::spawn(async move {
        let rpc_client = NodeRpcClient::new("http://127.0.0.1:8333");

        info!("🔄 Starting blockchain indexing...");

        // 초기 동기화
        match sync_blockchain(&db_sync, &rpc_client).await {
            Ok(()) => {
                info!("✅ Initial blockchain sync completed");
            }
            Err(e) => {
                error!("❌ Failed to sync blockchain on startup: {}", e);
            }
        }

        // 이후 10초마다 동기화
        let mut sync_interval = interval(Duration::from_secs(10));

        loop {
            sync_interval.tick().await;

            match sync_blockchain(&db_sync, &rpc_client).await {
                Ok(()) => {
                    // 성공 시 로그는 sync_blockchain 내부에서 처리
                }
                Err(e) => {
                    error!("❌ Failed to sync blockchain: {}", e);
                }
            }
        }
    });

    let server_address = "127.0.0.1";
    let server_port = 8080;

    info!(
        "📡 Server listening on http://{}:{}",
        server_address, server_port
    );

    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .app_data(web::Data::new(explorer_db.clone()))
            .wrap(middleware::Logger::default())
            .wrap(cors)
            .service(
                web::scope("/api")
                    .route("/health", web::get().to(handlers::health))
                    .route("/blocks", web::get().to(handlers::get_blocks))
                    .route(
                        "/blocks/{height}",
                        web::get().to(handlers::get_block_by_height),
                    )
                    .route(
                        "/blocks/hash/{hash}",
                        web::get().to(handlers::get_block_by_hash),
                    )
                    .route("/transactions", web::get().to(handlers::get_transactions))
                    .route(
                        "/transactions/{hash}",
                        web::get().to(handlers::get_transaction_by_hash),
                    )
                    .route("/stats", web::get().to(handlers::get_blockchain_stats))
                    .route(
                        "/address/{address}",
                        web::get().to(handlers::get_address_info),
                    ),
            )
    })
    .bind(format!("{}:{}", server_address, server_port))?
    .run()
    .await
}

/// 노드로부터 블록체인 데이터를 가져와 데이터베이스에 인덱싱
async fn sync_blockchain(db: &ExplorerDB, rpc_client: &NodeRpcClient) -> anyhow::Result<()> {
    // 마지막 동기화된 높이 가져오기
    let last_synced = db.get_last_synced_height()?;

    let mut utxo_map = std::collections::HashMap::new();
    let (blocks, transactions) = if last_synced == 0 {
        // 첫 동기화: 전체 블록체인 가져오기
        log::info!("🔄 Initial sync: fetching entire blockchain from Node");
        rpc_client
            .fetch_blockchain_with_transactions(&mut utxo_map)
            .await
            .map_err(|e| anyhow::anyhow!("Failed to fetch blockchain: {}", e))?
    } else {
        // 증분 동기화: 마지막 높이 이후만 가져오기
        log::info!(
            "🔄 Incremental sync from height {} (last synced: {})",
            last_synced + 1,
            last_synced
        );
        rpc_client
            .fetch_blocks_range(last_synced + 1, &mut utxo_map)
            .await
            .map_err(|e| anyhow::anyhow!("Failed to fetch blockchain: {}", e))?
    };

    if blocks.is_empty() {
        log::debug!("✅ No new blocks to sync");
        return Ok(());
    }

    let latest_height = blocks.iter().map(|b| b.height).max().unwrap_or(last_synced);

    // 모든 블록 인덱싱
    let mut new_blocks = 0;
    let mut new_transactions = 0;

    for block in &blocks {
        db.save_block(block)?;
        new_blocks += 1;
    }

    for tx in &transactions {
        db.save_transaction(tx)?;
        new_transactions += 1;

        // 관련 주소 정보 업데이트
        if let Err(e) = db.update_address_info(&tx.from) {
            error!("Failed to update address info for {}: {}", tx.from, e);
        }
        if let Err(e) = db.update_address_info(&tx.to) {
            error!("Failed to update address info for {}: {}", tx.to, e);
        }
    }

    // 메타데이터 업데이트
    db.set_block_count(latest_height)?;
    db.set_transaction_count(latest_height)?; // 각 블록당 1 tx (coinbase)
    db.set_last_synced_height(latest_height)?;

    if new_blocks > 0 || new_transactions > 0 {
        info!(
            "📊 Indexed {} new blocks, {} new transactions (Height: {} -> {}, Total: {} blocks, {} txs)",
            new_blocks, new_transactions, last_synced, latest_height, latest_height, latest_height
        );
    }

    Ok(())
}
