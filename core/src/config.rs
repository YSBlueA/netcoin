// Token economics and fee configuration for NTC blockchain
use primitive_types::U256;

// ========== Token Definition ==========
/// 1 NTC in natoshi (smallest unit) - 18 decimals like Ethereum
pub const NATOSHI_PER_NTC: U256 = U256([1_000_000_000_000_000_000, 0, 0, 0]);

/// Initial block reward: 8 NTC in natoshi
pub fn initial_block_reward() -> U256 {
    NATOSHI_PER_NTC * U256::from(8)
}

/// Halving occurs every 210,000 blocks (~4 years at 10 min block time)
pub const HALVING_INTERVAL: u64 = 210_000;

/// Max supply: 42,000,000 NTC in natoshi
pub fn max_supply() -> U256 {
    NATOSHI_PER_NTC * U256::from(42_000_000)
}

// ========== Fee Model ==========
// 🛡️ Anti-DDoS Fee Policy (EVM-compatible with 18 decimals)
// Fee structure similar to Ethereum to prevent spam while remaining affordable

/// Base minimum fee: 100 Twei (100 * 10^12 wei) = 0.0001 NTC
/// Comparable to Ethereum's typical base fee
/// In natoshi: 100,000,000,000,000 (100 trillion)
pub const BASE_MIN_FEE: U256 = U256([100_000_000_000_000, 0, 0, 0]);

/// Additional fee per byte: 200 Gwei/byte (200 * 10^9 wei/byte)
/// For a typical 300-byte transaction: adds ~0.00006 NTC
/// In natoshi: 200,000,000,000 (200 billion)
pub const MIN_RELAY_FEE_NAT_PER_BYTE: U256 = U256([200_000_000_000, 0, 0, 0]);

/// Default wallet fee per byte: 300 Gwei/byte (1.5x minimum for faster confirmation)
/// In natoshi: 300,000,000,000 (300 billion)
pub const DEFAULT_WALLET_FEE_NAT_PER_BYTE: U256 = U256([300_000_000_000, 0, 0, 0]);

// ========== Helper Functions ==========

/// Calculate block reward for given height based on halving schedule
pub fn calculate_block_reward(block_height: u64) -> U256 {
    let halvings = (block_height / HALVING_INTERVAL) as u32;

    if halvings >= 33 {
        // After 33 halvings, reward reaches effectively 0 (supply cap reached)
        return U256::zero();
    }

    initial_block_reward() >> halvings
}

/// Calculate minimum fee for transaction in natoshi based on transaction size
/// Formula: BASE_MIN_FEE + (size × MIN_RELAY_FEE_NAT_PER_BYTE)
/// Example: 300 bytes → 100,000,000,000,000 + (300 × 200,000,000,000) = 160 Twei = 0.00016 NTC
pub fn calculate_min_fee(tx_size_bytes: usize) -> U256 {
    BASE_MIN_FEE + (MIN_RELAY_FEE_NAT_PER_BYTE * U256::from(tx_size_bytes))
}

/// Calculate default wallet fee for transaction in natoshi based on transaction size
/// Formula: BASE_MIN_FEE + (size × DEFAULT_WALLET_FEE_NAT_PER_BYTE)
/// Example: 300 bytes → 100,000,000,000,000 + (300 × 300,000,000,000) = 190 Twei = 0.00019 NTC
pub fn calculate_default_fee(tx_size_bytes: usize) -> U256 {
    BASE_MIN_FEE + (DEFAULT_WALLET_FEE_NAT_PER_BYTE * U256::from(tx_size_bytes))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_initial_supply() {
        let reward = calculate_block_reward(0);
        assert_eq!(reward, NATOSHI_PER_NTC * U256::from(8));
    }

    #[test]
    fn test_first_halving() {
        let reward_before = calculate_block_reward(HALVING_INTERVAL - 1);
        let reward_after = calculate_block_reward(HALVING_INTERVAL);

        assert_eq!(reward_before, NATOSHI_PER_NTC * U256::from(8));
        assert_eq!(reward_after, NATOSHI_PER_NTC * U256::from(4));
    }

    #[test]
    fn test_fee_calculation() {
        // Standard transaction: 300 bytes (typical)
        let min_fee = calculate_min_fee(300);
        // BASE: 100,000,000,000,000 + (300 × 200,000,000,000) = 160,000,000,000,000 natoshi
        let expected_min =
            U256::from(100_000_000_000_000u64) + U256::from(300 * 200_000_000_000u64);
        assert_eq!(min_fee, expected_min); // 0.00016 NTC

        let default_fee = calculate_default_fee(300);
        // BASE: 100,000,000,000,000 + (300 × 300,000,000,000) = 190,000,000,000,000 natoshi
        let expected_default =
            U256::from(100_000_000_000_000u64) + U256::from(300 * 300_000_000_000u64);
        assert_eq!(default_fee, expected_default); // 0.00019 NTC
    }

    #[test]
    fn test_base_fee_prevents_spam() {
        // Even tiny transactions pay base fee (0.0001 NTC)
        let tiny_tx_fee = calculate_min_fee(100);
        assert!(tiny_tx_fee >= BASE_MIN_FEE);

        // Spam attack cost: 1,000,000 transactions (300 bytes each)
        let spam_cost = calculate_min_fee(300) * U256::from(1_000_000);
        // = 160,000,000,000,000,000,000 natoshi = 160 NTC
        // At $1/NTC: $160 total cost for 1M transactions
        // This makes spam attacks economically unfeasible!
        let ntc_160 = NATOSHI_PER_NTC * U256::from(160);
        assert_eq!(spam_cost, ntc_160);
    }
}
