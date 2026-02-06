# Astram DNS Server

Astram ?¤íŠ¸?Œí¬???¸ë“œ ?”ìŠ¤ì»¤ë²„ë¦¬ë? ?„í•œ DNS ?œë²„?…ë‹ˆ??

## ê¸°ëŠ¥

- ?¸ë“œ ?±ë¡ ë°?ê´€ë¦?
- ?¸ë“œ ëª©ë¡ ì¡°íšŒ
- ?ë™ ?¤ë˜???¸ë“œ ?•ë¦¬
- ?¸ë“œ ?µê³„ ?œê³µ

## ë¹Œë“œ ë°??¤í–‰

### DNS ?œë²„ ?¤í–‰

```bash
cd dns-server
cargo run
```

?ëŠ” ?¬íŠ¸?€ ìµœë? ?¸ë“œ ? íš¨ ?œê°„??ì§€??

```bash
cargo run -- --port 8053 --max-age 3600
```

### ?µì…˜

- `--port` ?ëŠ” `-p`: DNS ?œë²„ ?¬íŠ¸ (ê¸°ë³¸ê°? 8053)
- `--max-age` ?ëŠ” `-m`: ?¸ë“œ??ìµœë? ? íš¨ ?œê°„ (ì´??¨ìœ„, ê¸°ë³¸ê°? 3600)

## API ?”ë“œ?¬ì¸??

### 1. ?¸ë“œ ?±ë¡

**POST** `/register`

?¸ë“œë¥?DNS ?œë²„???±ë¡?©ë‹ˆ??

**?”ì²­ ë³¸ë¬¸:**

```json
{
  "address": "192.168.1.100",
  "port": 8333,
  "version": "0.1.0",
  "height": 12345
}
```

**?‘ë‹µ:**

```json
{
  "success": true,
  "message": "Node 192.168.1.100:8333 registered successfully",
  "node_count": 42
}
```

### 2. ?¸ë“œ ëª©ë¡ ì¡°íšŒ

**GET** `/nodes?limit=10&min_height=1000`

?±ë¡???¸ë“œ ëª©ë¡??ì¡°íšŒ?©ë‹ˆ??

**ì¿¼ë¦¬ ?Œë¼ë¯¸í„°:**

- `limit` (? íƒ): ë°˜í™˜??ìµœë? ?¸ë“œ ??
- `min_height` (? íƒ): ìµœì†Œ ë¸”ë¡ ?’ì´

**?‘ë‹µ:**

```json
{
  "nodes": [
    {
      "address": "192.168.1.100",
      "port": 8333,
      "version": "0.1.0",
      "height": 12345,
      "last_seen": 1737327600
    }
  ],
  "count": 1
}
```

### 3. ?œë²„ ?íƒœ ?•ì¸

**GET** `/health`

?œë²„???íƒœë¥??•ì¸?©ë‹ˆ??

**?‘ë‹µ:**

```json
{
  "status": "healthy",
  "node_count": 42,
  "timestamp": 1737327600
}
```

### 4. ?µê³„ ì¡°íšŒ

**GET** `/stats`

?¤íŠ¸?Œí¬ ?µê³„ë¥?ì¡°íšŒ?©ë‹ˆ??

**?‘ë‹µ:**

```json
{
  "node_count": 42,
  "max_height": 12500,
  "avg_height": 12000,
  "versions": {
    "0.1.0": 30,
    "0.1.1": 12
  },
  "timestamp": 1737327600
}
```

## P2P ?¸ë“œ?ì„œ DNS ?¬ìš©?˜ê¸°

### 1. DNS ?œë²„???¸ë“œ ?±ë¡

```rust
use std::sync::Arc;

// PeerManager ?ì„± ??
let peer_manager = Arc::new(PeerManager::new());

// DNS ?œë²„???±ë¡
let dns_server = "http://dns.Astram.org:8053";
let my_address = "192.168.1.100"; // ?¸ë??ì„œ ?‘ê·¼ ê°€?¥í•œ ì£¼ì†Œ
let my_port = 8333;

peer_manager
    .register_with_dns(dns_server, my_address, my_port)
    .await?;
```

### 2. ì£¼ê¸°?ìœ¼ë¡?DNS???±ë¡ (ë°±ê·¸?¼ìš´??

```rust
// 5ë¶„ë§ˆ??DNS???±ë¡
let peer_manager_clone = peer_manager.clone();
tokio::spawn(async move {
    peer_manager_clone
        .start_dns_registration_loop(
            "http://dns.Astram.org:8053".to_string(),
            "192.168.1.100".to_string(),
            8333,
            300, // 5ë¶„ë§ˆ??
        )
        .await;
});
```

### 3. DNS?ì„œ ?¼ì–´ ëª©ë¡ ê°€?¸ì˜¤ê¸?

```rust
// ìµœë? 20ê°œì˜ ?¸ë“œë¥?ê°€?¸ì˜´ (ìµœì†Œ ?’ì´ 1000 ?´ìƒ)
let peers = peer_manager
    .fetch_peers_from_dns(
        "http://dns.Astram.org:8053",
        Some(20),
        Some(1000),
    )
    .await?;

// ê°€?¸ì˜¨ ?¼ì–´?¤ì— ?°ê²°
for peer_addr in peers {
    let pm = peer_manager.clone();
    tokio::spawn(async move {
        if let Err(e) = pm.connect_peer(&peer_addr).await {
            log::warn!("Failed to connect to {}: {:?}", peer_addr, e);
        }
    });
}
```

## ?ˆì œ: ?„ì²´ ?¸ë“œ ?¤í–‰ ?ë¦„

```rust
use std::sync::Arc;
use Astram_node::p2p::PeerManager;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let peer_manager = Arc::new(PeerManager::new());

    // 1. DNS?ì„œ ?¼ì–´ ëª©ë¡ ê°€?¸ì˜¤ê¸?
    let dns_server = "http://dns.Astram.org:8053";
    let peers = peer_manager
        .fetch_peers_from_dns(dns_server, Some(10), None)
        .await?;

    // 2. ê°€?¸ì˜¨ ?¼ì–´?¤ì— ?°ê²°
    for peer_addr in peers {
        let pm = peer_manager.clone();
        tokio::spawn(async move {
            let _ = pm.connect_peer(&peer_addr).await;
        });
    }

    // 3. P2P ë¦¬ìŠ¤???œì‘
    let pm = peer_manager.clone();
    tokio::spawn(async move {
        pm.start_listener("0.0.0.0:8333").await.unwrap();
    });

    // 4. DNS ?±ë¡ ?œì‘ (5ë¶„ë§ˆ??
    let pm = peer_manager.clone();
    tokio::spawn(async move {
        pm.start_dns_registration_loop(
            dns_server.to_string(),
            "your.public.ip".to_string(),
            8333,
            300,
        ).await;
    });

    // ë©”ì¸ ë£¨í”„...
    tokio::signal::ctrl_c().await?;

    Ok(())
}
```

## Dockerë¡?DNS ?œë²„ ?¤í–‰

### Dockerfile

```dockerfile
FROM rust:1.75 as builder
WORKDIR /app
COPY dns-server/Cargo.toml dns-server/Cargo.lock ./
COPY dns-server/src ./src
RUN cargo build --release

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/Astram-dns /usr/local/bin/
EXPOSE 8053
CMD ["Astram-dns", "--port", "8053"]
```

### Docker Compose

```yaml
version: "3.8"

services:
  dns-server:
    build:
      context: .
      dockerfile: dns-server/Dockerfile
    ports:
      - "8053:8053"
    environment:
      - RUST_LOG=info
    restart: unless-stopped
```

?¤í–‰:

```bash
docker-compose up -d dns-server
```

## ë³´ì•ˆ ê³ ë ¤?¬í•­

1. **DDoS ë°©ì?**: ?„ë¡œ?•ì…˜ ?˜ê²½?ì„œ??rate limiting ì¶”ê? ê¶Œì¥
2. **?¸ì¦**: ?„ìš”??API ??ê¸°ë°˜ ?¸ì¦ ì¶”ê?
3. **HTTPS**: ?„ë¡œ?•ì…˜?ì„œ??ë¦¬ë²„???„ë¡??nginx, caddy)ë¥??µí•œ HTTPS ?¬ìš© ê¶Œì¥
4. **?¸ë“œ ê²€ì¦?*: ?±ë¡???¸ë“œ???¤ì œ ?‘ê·¼ ê°€???¬ë? ê²€ì¦?ë¡œì§ ì¶”ê? ê³ ë ¤

## ëª¨ë‹ˆ?°ë§

DNS ?œë²„ ?íƒœ??`/health` ?”ë“œ?¬ì¸?¸ë¡œ ëª¨ë‹ˆ?°ë§?????ˆìŠµ?ˆë‹¤:

```bash
curl http://localhost:8053/health
```

?µê³„ ?•ì¸:

```bash
curl http://localhost:8053/stats
```

## ?¼ì´? ìŠ¤

MIT

