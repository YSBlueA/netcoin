use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockInfo {
    pub height: u64,
    pub hash: String,
    pub timestamp: DateTime<Utc>,
    pub transactions: usize,
    pub miner: String,
    pub difficulty: u32,
    pub nonce: u64,
    pub previous_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionInfo {
    pub hash: String,
    pub from: String,
    pub to: String,
    pub amount: u64,
    pub fee: u64,
    pub timestamp: DateTime<Utc>,
    pub block_height: Option<u64>,
    pub status: String, // "confirmed", "pending"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AddressInfo {
    pub address: String,
    pub balance: u64,
    pub sent: u64,
    pub received: u64,
    pub transaction_count: usize,
    pub last_transaction: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockchainStats {
    pub total_blocks: u64,
    pub total_transactions: u64,
    pub total_volume: u64,
    pub average_block_time: f64,
    pub average_block_size: usize,
    pub current_difficulty: u32,
    pub network_hashrate: String,
}

pub struct AppState {
    pub cached_blocks: Vec<BlockInfo>,
    pub cached_transactions: Vec<TransactionInfo>,
    pub last_update: chrono::DateTime<Utc>,
}

impl AppState {
    pub fn new() -> Self {
        let mut state = AppState {
            cached_blocks: Vec::new(),
            cached_transactions: Vec::new(),
            last_update: Utc::now(),
        };
        state.load_sample_data();
        state
    }

    fn load_sample_data(&mut self) {
        let now = Utc::now();

        // 샘플 블록 10개 추가
        for i in 0..10 {
            self.cached_blocks.push(BlockInfo {
                height: i as u64,
                hash: format!("0x{:064x}", i * 12345 + 999),
                timestamp: now - chrono::Duration::minutes(10 * (10 - i as i64)),
                transactions: ((i + 1) * 5),
                miner: format!("NetCoin_Miner_{:02}", i),
                difficulty: 1000 + (i as u32 * 50),
                nonce: 123456 + i as u64,
                previous_hash: if i == 0 {
                    "0x0000000000000000000000000000000000000000000000000000000000000000".to_string()
                } else {
                    format!("0x{:064x}", (i - 1) * 12345 + 999)
                },
            });
        }

        // 샘플 트랜잭션 20개 추가
        for i in 0..20 {
            self.cached_transactions.push(TransactionInfo {
                hash: format!("0x{:064x}", i * 54321 + 888),
                from: format!("netcoin_{:02x}", i % 3),
                to: format!("netcoin_{:02x}", (i + 1) % 4),
                amount: 1_000_000_000 + (i as u64 * 50_000_000),
                fee: 50_000,
                timestamp: now - chrono::Duration::minutes(2 * (20 - i as i64)),
                block_height: Some((i as u64) / 2),
                status: if i < 15 { "confirmed".to_string() } else { "pending".to_string() },
            });
        }
    }
}
