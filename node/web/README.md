#+#+#+#+ Astram Node Dashboard

Astram provides a lightweight dashboard for monitoring a running node.

## Access

If the node is running, open the dashboard in your browser:

```
http://localhost:8333
```

## Dashboard Features

### Real-time monitoring

The dashboard refreshes every 5 seconds and shows:

#### Node info

- Node version
- Network status
- Uptime
- Last update time

#### Mining status

- Mining active/inactive
- Current hashrate (H/s, KH/s, MH/s, GH/s, TH/s)
- Current difficulty
- Blocks mined

#### Wallet info

- Wallet address
- Current balance (ASRM)

#### Blockchain status

- Current block height
- Blocks loaded in memory
- P2P sync height
- Current difficulty
- Chain tip hash

#### Mempool status

- Pending transaction count
- Seen transaction count

#### Network status

- Connected peer count
- Peer height list

### Auto refresh

- Auto refresh every 5 seconds by default
- Toggle auto refresh on/off
- Manual refresh button updates immediately

## Design Notes

### Visual cues

- Mining card highlights while mining is active
- Wallet card uses an accent border
- Minimal UI with focus on status
- Responsive layout (mobile friendly)

### Mobile

- Optimized for phone and tablet
- Touch-friendly controls

## Tech Stack

- Frontend: Vanilla JavaScript + HTML5 + CSS3
- Backend: Rust (Warp framework)
- API: RESTful JSON API

## API Endpoints

The dashboard uses:

```
GET /status
```

Response example:

```json
{
  "node": {
    "version": "0.1.0",
    "uptime_seconds": 3600
  },
  "blockchain": {
    "height": 1000,
    "memory_blocks": 100,
    "chain_tip": "000...",
    "my_height": 1000,
    "difficulty": 5
  },
  "mempool": {
    "pending_transactions": 5,
    "seen_transactions": 150
  },
  "network": {
    "connected_peers": 3,
    "peer_heights": {
      "peer1": 1000,
      "peer2": 999
    }
  },
  "mining": {
    "active": true,
    "hashrate": 1234567.89,
    "difficulty": 5,
    "blocks_mined": 10
  },
  "wallet": {
    "address": "0x...",
    "balance": "0x..."
  },
  "timestamp": "2026-02-03T12:00:00Z"
}
```

## Troubleshooting

### Dashboard does not load

1. Verify the node is running (http://localhost:8333 should respond).
2. Check the browser console for errors.
3. Check the node logs.

### Data does not update

- Verify auto refresh is enabled.
- Click the manual refresh button.
- Hard refresh the browser (F5).

## Explorer vs Dashboard

- Node Dashboard (http://localhost:8333): Node operation, mining, wallet, and network status
- Explorer (http://localhost:8080): Public chain browsing and block/tx lookup

Both run on different ports and can be used together.
