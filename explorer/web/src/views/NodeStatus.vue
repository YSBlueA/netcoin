<template>
  <div class="node-status">
    <h1>Node Dashboard</h1>

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>Loading node status...</p>
    </div>

    <div v-else-if="error" class="error-message">
      <h3>Cannot connect to node</h3>
      <p>{{ error }}</p>
      <button @click="fetchStatus" class="retry-btn">Retry</button>
    </div>

    <div v-else class="status-container">
      <!-- Node Information -->
      <div class="status-card">
        <h2>Node Information</h2>
        <div class="info-grid">
          <div class="info-item">
            <span class="label">Version:</span>
            <span class="value">{{ status.node?.version || "N/A" }}</span>
          </div>
          <div class="info-item">
            <span class="label">Status:</span>
            <span class="value status-online">Online</span>
          </div>
          <div class="info-item">
            <span class="label">Uptime:</span>
            <span class="value">{{
              formatUptime(status.node?.uptime_seconds)
            }}</span>
          </div>
          <div class="info-item">
            <span class="label">Last Update:</span>
            <span class="value">{{ formatTimestamp(status.timestamp) }}</span>
          </div>
        </div>
      </div>

      <!-- Mining Status -->
      <div
        class="status-card mining-card"
        :class="{ active: status.mining?.active }"
      >
        <h2>Mining Status</h2>
        <div class="info-grid">
          <div class="info-item highlight">
            <span class="label">Status:</span>
            <span
              class="value"
              :class="
                status.mining?.active ? 'mining-active' : 'mining-inactive'
              "
            >
              {{ status.mining?.active ? "Mining" : "Idle" }}
            </span>
          </div>
          <div class="info-item">
            <span class="label">Hashrate:</span>
            <span class="value">{{
              formatHashrate(status.mining?.hashrate)
            }}</span>
          </div>
          <div class="info-item">
            <span class="label">Current Difficulty:</span>
            <span class="value">{{
              status.mining?.difficulty || status.blockchain?.difficulty || 0
            }}</span>
          </div>
          <div class="info-item">
            <span class="label">Blocks Mined:</span>
            <span class="value">{{ status.mining?.blocks_mined || 0 }}</span>
          </div>
        </div>
      </div>

      <!-- Wallet Information -->
      <div class="status-card wallet-card">
        <h2>Wallet Information</h2>
        <div class="info-grid">
          <div class="info-item full-width">
            <span class="label">Address:</span>
            <span class="value hash">{{ status.wallet?.address || 'N/A' }}</span>
          </div>
          <div class="info-item highlight">
            <span class="label">Balance:</span>
            <span class="value balance">{{ formatBalance(status.wallet?.balance) }}</span>
          </div>
        </div>
      </div>

      <!-- Blockchain Information -->
      <div class="status-card">
        <h2>Blockchain Status</h2>
        <div class="info-grid">
          <div class="info-item highlight">
            <span class="label">Current Height:</span>
            <span class="value">{{ status.blockchain?.height || 0 }}</span>
          </div>
          <div class="info-item">
            <span class="label">Memory Blocks:</span>
            <span class="value">{{
              status.blockchain?.memory_blocks || 0
            }}</span>
          </div>
          <div class="info-item">
            <span class="label">Sync Height:</span>
            <span class="value">{{ status.blockchain?.my_height || 0 }}</span>
          </div>
          <div class="info-item">
            <span class="label">Difficulty:</span>
            <span class="value">{{ status.blockchain?.difficulty || 1 }}</span>
          </div>
          <div class="info-item full-width">
            <span class="label">Chain Tip Hash:</span>
            <span class="value hash">{{
              formatHash(status.blockchain?.chain_tip)
            }}</span>
          </div>
        </div>
      </div>

      <!-- Mempool Information -->
      <div class="status-card">
        <h2>Mempool Status</h2>
        <div class="info-grid">
          <div class="info-item highlight">
            <span class="label">Pending Transactions:</span>
            <span class="value">{{
              status.mempool?.pending_transactions || 0
            }}</span>
          </div>
          <div class="info-item">
            <span class="label">Seen Transactions:</span>
            <span class="value">{{
              status.mempool?.seen_transactions || 0
            }}</span>
          </div>
        </div>
      </div>

      <!-- Network Information -->
      <div class="status-card">
        <h2>Network Status</h2>
        <div class="info-grid">
          <div class="info-item highlight">
            <span class="label">Connected Peers:</span>
            <span class="value">{{
              status.network?.connected_peers || 0
            }}</span>
          </div>
        </div>

        <!-- Peer List -->
        <div v-if="peerHeights.length > 0" class="peer-list">
          <h3>Peer List</h3>
          <div class="peer-item" v-for="peer in peerHeights" :key="peer.id">
            <span class="peer-id">{{ peer.id }}</span>
            <span class="peer-height">Block Height: {{ peer.height }}</span>
          </div>
        </div>
        <div v-else class="no-peers">
          <p>No connected peers</p>
        </div>
      </div>

      <!-- Auto Refresh Settings -->
      <div class="auto-refresh-control">
        <label>
          <input
            type="checkbox"
            v-model="autoRefresh"
            @change="toggleAutoRefresh"
          />
          <span>Auto Refresh (every {{ refreshInterval / 1000 }} seconds)</span>
        </label>
        <button @click="fetchStatus" class="refresh-btn">
          Manual Refresh
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, onUnmounted, computed } from "vue";
import { explorerAPI } from "../api/explorer";

export default {
  name: "NodeStatus",
  setup() {
    const status = ref(null);
    const loading = ref(true);
    const error = ref(null);
    const autoRefresh = ref(true);
    const refreshInterval = ref(5000); // 5 seconds
    let refreshTimer = null;

    const peerHeights = computed(() => {
      if (!status.value?.network?.peer_heights) return [];
      const peers = status.value.network.peer_heights;
      return Object.entries(peers).map(([id, height]) => ({ id, height }));
    });

    const fetchStatus = async () => {
      try {
        loading.value = true;
        error.value = null;
        const response = await explorerAPI.getNodeStatus();
        status.value = response.data;
      } catch (err) {
        console.error("Failed to fetch node status:", err);
        error.value =
          err.response?.data?.message || "Unable to fetch node status";
      } finally {
        loading.value = false;
      }
    };

    const toggleAutoRefresh = () => {
      if (autoRefresh.value) {
        startAutoRefresh();
      } else {
        stopAutoRefresh();
      }
    };

    const startAutoRefresh = () => {
      stopAutoRefresh();
      refreshTimer = setInterval(fetchStatus, refreshInterval.value);
    };

    const stopAutoRefresh = () => {
      if (refreshTimer) {
        clearInterval(refreshTimer);
        refreshTimer = null;
      }
    };

    const formatTimestamp = (timestamp) => {
      if (!timestamp) return "N/A";
      const date = new Date(timestamp);
      return date.toLocaleString("ko-KR");
    };

    const formatHash = (hash) => {
      if (!hash || hash === "none") return "N/A";
      if (hash.length > 16) {
        return hash.substring(0, 8) + "..." + hash.substring(hash.length - 8);
      }
      return hash;
    };

    const formatUptime = (seconds) => {
      if (!seconds) return "N/A";
      const hours = Math.floor(seconds / 3600);
      const minutes = Math.floor((seconds % 3600) / 60);
      const secs = seconds % 60;

      if (hours > 0) {
        return `${hours}h ${minutes}m`;
      } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
      } else {
        return `${secs}s`;
      }
    };

    const formatHashrate = (hashrate) => {
      if (!hashrate || hashrate === 0) return "0 H/s";

      if (hashrate >= 1e12) {
        return `${(hashrate / 1e12).toFixed(2)} TH/s`;
      } else if (hashrate >= 1e9) {
        return `${(hashrate / 1e9).toFixed(2)} GH/s`;
      } else if (hashrate >= 1e6) {
        return `${(hashrate / 1e6).toFixed(2)} MH/s`;
      } else if (hashrate >= 1e3) {
        return `${(hashrate / 1e3).toFixed(2)} KH/s`;
      } else {
        return `${hashrate.toFixed(2)} H/s`;
      }
    };

    const formatBalance = (balanceHex) => {
      if (!balanceHex) return "0 ASRM";
      
      try {
        // Remove 0x prefix if present
        const hex = balanceHex.startsWith("0x") ? balanceHex.slice(2) : balanceHex;
        // Convert hex to BigInt
        const wei = BigInt("0x" + hex);
        // Convert to ASRM (18 decimals)
        const ASRM = Number(wei) / 1e18;
        
        return `${ASRM.toFixed(4)} ASRM`;
      } catch (e) {
        console.error("Error formatting balance:", e);
        return "0 ASRM";
      }
    };

    onMounted(() => {
      fetchStatus();
      if (autoRefresh.value) {
        startAutoRefresh();
      }
    });

    onUnmounted(() => {
      stopAutoRefresh();
    });

    return {
      status,
      loading,
      error,
      autoRefresh,
      refreshInterval,
      peerHeights,
      fetchStatus,
      toggleAutoRefresh,
      formatTimestamp,
      formatHash,
      formatUptime,
      formatHashrate,
      formatBalance,
    };
  },
};
</script>

<style scoped>
.node-status {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

h1 {
  font-size: 2.5rem;
  margin-bottom: 2rem;
  color: #2c3e50;
  text-align: center;
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.error-message {
  background-color: #fee;
  border: 1px solid #fcc;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
}

.error-message h3 {
  color: #c33;
  margin-bottom: 1rem;
}

.retry-btn {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: background-color 0.3s;
}

.retry-btn:hover {
  background-color: #2980b9;
}

.status-container {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.status-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  transition:
    transform 0.2s,
    box-shadow 0.2s;
}

.status-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}

.mining-card {
  border: 2px solid #eee;
}

.mining-card.active {
  border-color: #27ae60;
  background: linear-gradient(to right, #ffffff, #e8f5e9);
}

.wallet-card {
  border: 2px solid #f39c12;
  background: linear-gradient(to right, #ffffff, #fef5e7);
}

.status-card h2 {
  font-size: 1.4rem;
  margin-bottom: 1rem;
  color: #2c3e50;
  border-bottom: 2px solid #3498db;
  padding-bottom: 0.5rem;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  padding: 0.75rem;
  background: #f8f9fa;
  border-radius: 6px;
  transition: background-color 0.2s;
}

.info-item:hover {
  background: #e9ecef;
}

.info-item.highlight {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  border-left: 4px solid #3498db;
}

.info-item.full-width {
  grid-column: 1 / -1;
}

.info-item .label {
  font-size: 0.85rem;
  color: #666;
  margin-bottom: 0.25rem;
  font-weight: 500;
}

.info-item .value {
  font-size: 1.2rem;
  font-weight: 600;
  color: #2c3e50;
}

.value.hash {
  font-family: "Courier New", monospace;
  font-size: 0.9rem;
  word-break: break-all;
}

.value.status-online {
  color: #27ae60;
}

.value.mining-active {
  color: #27ae60;
  animation: pulse 2s infinite;
}

.value.mining-inactive {
  color: #95a5a6;
}

.value.balance {
  color: #f39c12;
  font-size: 1.3rem;
  font-weight: 700;
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.peer-list {
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid #eee;
}

.peer-list h3 {
  font-size: 1rem;
  margin-bottom: 0.75rem;
  color: #555;
}

.peer-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: #f8f9fa;
  border-radius: 6px;
  margin-bottom: 0.5rem;
  transition: background-color 0.2s;
}

.peer-item:hover {
  background: #e9ecef;
}

.peer-id {
  font-family: "Courier New", monospace;
  font-size: 0.85rem;
  color: #555;
}

.peer-height {
  font-weight: 600;
  color: #3498db;
  background: #e3f2fd;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
}

.no-peers {
  padding: 1.5rem;
  text-align: center;
  color: #999;
  font-style: italic;
  background: #f8f9fa;
  border-radius: 6px;
  margin-top: 1rem;
}

.auto-refresh-control {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}

.auto-refresh-control label {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  font-weight: 500;
  color: #2c3e50;
}

.auto-refresh-control input[type="checkbox"] {
  width: 20px;
  height: 20px;
  cursor: pointer;
}

.refresh-btn {
  padding: 0.75rem 1.5rem;
  background: linear-gradient(135deg, #3498db 0%, #2980b9 100%);
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.95rem;
  font-weight: 600;
  transition:
    transform 0.2s,
    box-shadow 0.2s;
}

.refresh-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(52, 152, 219, 0.3);
}

.refresh-btn:active {
  transform: translateY(0);
}

@media (max-width: 768px) {
  h1 {
    font-size: 1.8rem;
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .auto-refresh-control {
    flex-direction: column;
    gap: 1rem;
  }

  .refresh-btn {
    width: 100%;
  }
}
</style>

