// node/src/p2p/service.rs
use crate::NodeHandle;
use crate::p2p::manager::{MAX_OUTBOUND, PeerManager};
use hex;
use log::{info, warn};
use netcoin_core::block;
use std::collections::HashSet;
use std::sync::Arc;
use tokio::time::{Duration, sleep};

pub struct P2PService {
    pub manager: Arc<PeerManager>,
}

impl P2PService {
    pub fn new() -> Self {
        Self {
            manager: Arc::new(PeerManager::new()),
        }
    }

    pub fn manager(&self) -> Arc<PeerManager> {
        self.manager.clone()
    }

    pub async fn start(&self, bind_addr: String, node_handle: NodeHandle) -> anyhow::Result<()> {
        self.start_listener(bind_addr).await;
        self.connect_initial_peers().await;
        self.register_handlers(node_handle.clone());
        self.start_header_sync(node_handle.clone());

        Ok(())
    }

    async fn start_listener(&self, addr: String) {
        let p2p = self.manager.clone();

        tokio::spawn(async move {
            if let Err(e) = p2p.start_listener(&addr).await {
                log::error!("P2P listener failed: {:?}", e);
            }
        });
    }

    async fn connect_initial_peers(&self) {
        let p2p = self.manager.clone();

        let dns_list = p2p.dns_seed_lookup().await.unwrap_or_default();
        let saved_list = p2p.load_saved_peers();

        let mut peers = HashSet::new();
        for addr in dns_list {
            peers.insert(addr);
        }
        for sp in saved_list {
            peers.insert(sp.addr);
        }

        for addr in peers.into_iter().take(MAX_OUTBOUND) {
            let p2p_clone = p2p.clone();
            tokio::spawn(async move {
                if let Err(e) = p2p_clone.connect_peer(&addr).await {
                    warn!("Failed connect {}: {:?}", addr, e);
                }
            });
        }
    }

    fn register_handlers(&self, node_handle: NodeHandle) {
        let p2p = self.manager.clone();

        // getheaders handler
        let nh = node_handle.clone();
        p2p.set_on_getheaders(move |_, _| {
            let state = nh.lock().unwrap();
            let mut headers = state
                .blockchain
                .iter()
                .rev()
                .take(200)
                .map(|b| b.header.clone())
                .collect::<Vec<_>>();
            headers.reverse();
            headers
        });

        // block handler
        let nh2 = node_handle.clone();
        p2p.set_on_block(move |block: block::Block| {
            let nh_async = nh2.clone();
            tokio::spawn(async move {
                let mut state = nh_async.lock().unwrap();

                // Cancel ongoing mining when receiving a new block
                state
                    .mining_cancel_flag
                    .store(true, std::sync::atomic::Ordering::SeqCst);

                match state.bc.validate_and_insert_block(&block) {
                    Ok(_) => {
                        info!(
                            "✅ Block added via p2p: index={} hash={}",
                            block.header.index, block.hash
                        );
                        state.blockchain.push(block.clone());

                        // Remove transactions from pending pool that are in the new block
                        let block_txids: std::collections::HashSet<String> = block
                            .transactions
                            .iter()
                            .map(|tx| tx.txid.clone())
                            .collect();

                        let removed_count = block_txids.len().saturating_sub(1); // -1 for coinbase
                        state.pending.retain(|tx| !block_txids.contains(&tx.txid));

                        if removed_count > 0 {
                            info!(
                                "🗑️  Removed {} transactions from mempool (included in peer block)",
                                removed_count
                            );
                        }
                        info!("⛏️  Mining cancelled, restarting with updated chain...");
                    }
                    Err(e) => warn!("❌ Invalid block from p2p: {:?}", e),
                }
            });
        });

        // transaction handler
        let nh3 = node_handle.clone();
        p2p.set_on_tx(move |tx: netcoin_core::transaction::Transaction| {
            let nh_async = nh3.clone();
            tokio::spawn(async move {
                let mut state = nh_async.lock().unwrap();

                // Check if transaction already exists in pending pool
                if state.pending.iter().any(|t| t.txid == tx.txid) {
                    info!("Transaction {} already in mempool, skipping", tx.txid);
                    return;
                }

                // Validate transaction signatures
                match tx.verify_signatures() {
                    Ok(true) => {
                        info!("✅ Transaction {} received and validated from p2p", tx.txid);
                        state.pending.push(tx);
                        info!("📝 Mempool size: {} transactions", state.pending.len());
                    }
                    Ok(false) => {
                        warn!("❌ Invalid transaction signature: {}", tx.txid);
                    }
                    Err(e) => {
                        warn!("❌ Transaction validation error {}: {:?}", tx.txid, e);
                    }
                }
            });
        });
    }

    fn start_header_sync(&self, node_handle: NodeHandle) {
        let p2p = self.manager.clone();
        tokio::spawn(async move {
            loop {
                let mut locator = Vec::new();
                {
                    let state = node_handle.lock().unwrap();
                    for b in state.blockchain.iter().rev().take(10) {
                        if let Ok(bytes) = hex::decode(&b.hash) {
                            locator.push(bytes);
                        }
                    }
                }
                p2p.request_headers_from_peers(locator, None);
                sleep(Duration::from_secs(15)).await;
            }
        });
    }
}
