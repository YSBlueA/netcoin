<template>
  <div class="blocks-page">
    <h1>Block List</h1>

    <div v-if="blocks.length" class="blocks-table">
      <table>
        <thead>
          <tr>
            <th>Height</th>
            <th>Hash</th>
            <th>Miner</th>
            <th>Transactions</th>
            <th>Timestamp</th>
            <th>Difficulty</th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="block in blocks"
            :key="block.hash"
            @click="goToBlockDetail(block.height)"
            class="table-row"
          >
            <td class="height">#{{ block.height }}</td>
            <td class="hash">{{ truncateHash(block.hash) }}</td>
            <td class="miner">{{ truncateAddress(block.miner) }}</td>
            <td class="txs">{{ block.transactions }}</td>
            <td class="timestamp">{{ formatTime(block.timestamp) }}</td>
            <td class="difficulty">{{ block.difficulty }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-else class="loading">Loading...</div>

    <div class="pagination">
      <button
        @click="previousPage"
        :disabled="currentPage === 1"
        class="nav-btn"
      >
        Previous
      </button>
      <span class="page-info">{{ currentPage }} / {{ totalPages }}</span>
      <button
        @click="nextPage"
        :disabled="currentPage >= totalPages"
        class="nav-btn"
      >
        Next
      </button>
    </div>
  </div>
</template>

<script>
import { explorerAPI } from "../api/explorer";

export default {
  name: "Blocks",
  data() {
    return {
      blocks: [],
      currentPage: 1,
      limit: 20,
      total: 0,
      refreshInterval: null,
    };
  },
  computed: {
    totalPages() {
      return Math.ceil(this.total / this.limit);
    },
  },
  mounted() {
    this.fetchBlocks();
    // Auto refresh every 5 seconds (sync latest blocks)
    this.refreshInterval = setInterval(() => this.fetchBlocks(), 5000);
  },
  beforeUnmount() {
    // Clear interval when component unmounts
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
  },
  methods: {
    async fetchBlocks() {
      try {
        const res = await explorerAPI.getBlocks(this.currentPage, this.limit);
        this.blocks = res.data.blocks;
        this.total = res.data.total;
      } catch (error) {
        console.error("Failed to load blocks:", error);
      }
    },
    previousPage() {
      if (this.currentPage > 1) {
        this.currentPage--;
        this.fetchBlocks();
      }
    },
    nextPage() {
      if (this.currentPage < this.totalPages) {
        this.currentPage++;
        this.fetchBlocks();
      }
    },
    goToBlockDetail(height) {
      this.$router.push(`/blocks/${height}`);
    },
    formatTime(timestamp) {
      const date = new Date(timestamp);
      return date.toLocaleString("ko-KR");
    },
    truncateHash(hash) {
      return hash.substring(0, 12) + "...";
    },
    truncateAddress(address) {
      return (
        address.substring(0, 8) + "..." + address.substring(address.length - 4)
      );
    },
  },
};
</script>

<style scoped>
.blocks-page {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

h1 {
  margin-bottom: 2rem;
  color: #667eea;
}

.blocks-table {
  overflow-x: auto;
  margin-bottom: 2rem;
}

table {
  width: 100%;
  border-collapse: collapse;
}

thead {
  background-color: #f5f5f5;
}

th {
  padding: 1rem;
  text-align: left;
  font-weight: bold;
  color: #333;
  border-bottom: 2px solid #ddd;
}

td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #eee;
}

.table-row {
  cursor: pointer;
  transition: background-color 0.3s;
}

.table-row:hover {
  background-color: #f8f9ff;
}

.height {
  color: #667eea;
  font-weight: bold;
}

.hash,
.miner {
  font-family: "Courier New", monospace;
  font-size: 0.9rem;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
}

.nav-btn {
  padding: 0.5rem 1rem;
  background-color: #667eea;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: opacity 0.3s;
}

.nav-btn:hover:not(:disabled) {
  opacity: 0.8;
}

.nav-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-info {
  font-weight: bold;
  color: #666;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: #999;
}
</style>
