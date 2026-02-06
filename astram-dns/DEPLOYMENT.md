# Astram DNS ?œë²„ ë°°í¬ ê°€?´ë“œ

## ?œë²„ ?•ë³´
- **IP**: 161.33.19.183
- **OS**: Ubuntu 24.04
- **Port**: 8053

## ë°°í¬ ë°©ë²•

### 1. ?œë²„???Œì¼ ?…ë¡œ??
ë¡œì»¬?ì„œ ?œë²„ë¡??„ë¡œ?íŠ¸ ?„ì²´ë¥?ë³µì‚¬?©ë‹ˆ??

```bash
# Windows?ì„œ scp ?¬ìš© (PowerShell)
scp -r d:\coin\Astram\Astram-dns user@161.33.19.183:~/Astram-dns

# ?ëŠ” rsync ?¬ìš© (WSL/Git Bash)
rsync -avz d:/coin/Astram/Astram-dns/ user@161.33.19.183:~/Astram-dns/
```

### 2. ?œë²„??SSH ?‘ì†

```bash
ssh user@161.33.19.183
```

### 3. ë°°í¬ ?¤í¬ë¦½íŠ¸ ?¤í–‰

```bash
cd ~/Astram-dns
chmod +x deploy.sh
./deploy.sh
```

???¤í¬ë¦½íŠ¸???ë™?¼ë¡œ:
- Rust ?¤ì¹˜ (?„ìš”??ê²½ìš°)
- ?„ë¡œ?íŠ¸ ë¹Œë“œ
- systemd ?œë¹„???¤ì •
- ?œë¹„???œì‘ ë°??œì„±??
### 4. ë°©í™”ë²??¤ì •

?¬íŠ¸ 8053???´ì–´ì¤ë‹ˆ??

```bash
# UFW ?¬ìš©?˜ëŠ” ê²½ìš°
sudo ufw allow 8053/tcp

# iptables ?¬ìš©?˜ëŠ” ê²½ìš°
sudo iptables -A INPUT -p tcp --dport 8053 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

## ?¸ë“œ ?±ë¡ ë°©ë²•

### ?ì‹ ???¸ë“œë¥?DNS ?œë²„???±ë¡

```bash
curl -X POST http://161.33.19.183:8053/register \
  -H "Content-Type: application/json" \
  -d '{
    "address": "YOUR_NODE_IP",
    "port": 8333,
    "version": "0.1.0",
    "height": 0
  }'
```

### ?ˆì‹œ (ë¡œì»¬ ?¸ë“œ ?±ë¡)

```bash
curl -X POST http://161.33.19.183:8053/register \
  -H "Content-Type: application/json" \
  -d '{
    "address": "192.168.1.100",
    "port": 8333,
    "version": "0.1.0",
    "height": 1
  }'
```

## API ?”ë“œ?¬ì¸??
### ?¬ìŠ¤ ì²´í¬
```bash
curl http://161.33.19.183:8053/health
```

### ?¸ë“œ ëª©ë¡ ì¡°íšŒ
```bash
# ëª¨ë“  ?¸ë“œ
curl http://161.33.19.183:8053/nodes

# ìµœë? 10ê°??¸ë“œ
curl http://161.33.19.183:8053/nodes?limit=10

# ìµœì†Œ ?’ì´ 100 ?´ìƒ???¸ë“œ
curl http://161.33.19.183:8053/nodes?min_height=100
```

### ?µê³„ ì¡°íšŒ
```bash
curl http://161.33.19.183:8053/stats
```

## ?œë¹„??ê´€ë¦?
### ?íƒœ ?•ì¸
```bash
sudo systemctl status Astram-dns
```

### ë¡œê·¸ ?•ì¸
```bash
# ?¤ì‹œê°?ë¡œê·¸
sudo journalctl -u Astram-dns -f

# ìµœê·¼ 100ì¤?sudo journalctl -u Astram-dns -n 100
```

### ?œë¹„???¬ì‹œ??```bash
sudo systemctl restart Astram-dns
```

### ?œë¹„??ì¤‘ì?
```bash
sudo systemctl stop Astram-dns
```

### ?œë¹„???œì‘
```bash
sudo systemctl start Astram-dns
```

## ?¸ë“œ?ì„œ DNS ?œë²„ ?¬ìš©?˜ê¸°

Astram ?¸ë“œ???¤ì • ?Œì¼??DNS ?œë²„ ì£¼ì†Œë¥?ì¶”ê?:

```toml
[network]
dns_servers = ["http://161.33.19.183:8053"]
```

?ëŠ” ?¸ë“œ ?œì‘ ???Œë¼ë¯¸í„°ë¡??„ë‹¬:

```bash
Astram-node --dns-server http://161.33.19.183:8053
```

## ?˜ë™ ë¹Œë“œ ë°??¤í–‰ (ë°°í¬ ?¤í¬ë¦½íŠ¸ ?¬ìš©?˜ì? ?ŠëŠ” ê²½ìš°)

### ë¹Œë“œ
```bash
cd ~/Astram-dns
cargo build --release
```

### ?¤í–‰
```bash
# ê¸°ë³¸ ?¤ì •?¼ë¡œ ?¤í–‰
./target/release/Astram-dns

# ì»¤ìŠ¤?€ ?¬íŠ¸?€ ìµœë? ?¸ë“œ ? íš¨ ?œê°„
./target/release/Astram-dns --port 8053 --max-age 7200
```

## ?¸ëŸ¬ë¸”ìŠˆ??
### ?¬íŠ¸ê°€ ?´ë? ?¬ìš© ì¤‘ì¸ ê²½ìš°
```bash
# ?¬íŠ¸ ?¬ìš© ?•ì¸
sudo netstat -tulpn | grep 8053

# ?„ë¡œ?¸ìŠ¤ ì¢…ë£Œ
sudo kill -9 <PID>
```

### ?œë¹„?¤ê? ?œì‘?˜ì? ?ŠëŠ” ê²½ìš°
```bash
# ?ì„¸ ë¡œê·¸ ?•ì¸
sudo journalctl -u Astram-dns -n 50 --no-pager

# ?œë¹„???Œì¼ ?¬ë¡œ??sudo systemctl daemon-reload
sudo systemctl restart Astram-dns
```

### Rustê°€ ?¤ì¹˜?˜ì? ?ŠëŠ” ê²½ìš°
```bash
# ?˜ë™ ?¤ì¹˜
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

## ?…ë°?´íŠ¸ ë°©ë²•

ì½”ë“œë¥??˜ì •????

```bash
# ë¡œì»¬?ì„œ ?œë²„ë¡??…ë¡œ??scp -r d:\coin\Astram\Astram-dns user@161.33.19.183:~/Astram-dns

# ?œë²„?ì„œ
cd ~/Astram-dns
cargo build --release
sudo cp target/release/Astram-dns /usr/local/bin/
sudo systemctl restart Astram-dns
```

## ?„ë©”???¬ìš©?˜ê¸°

### ?„ë©”???¤ì • ???¬ìš© ë°©ë²•

?„ë©”???? dns.Astram.com)???¤ì •???„ì—??IP ì£¼ì†Œ ?€???„ë©”?¸ì„ ?¬ìš©?????ˆìŠµ?ˆë‹¤.

#### 1. ?˜ê²½ ë³€?˜ë¡œ ?¤ì •

```bash
# ?˜ê²½ ë³€???¤ì •
export DNS_SERVER="http://dns.Astram.com:8053"

# ?ëŠ” HTTPS ?¬ìš©
export DNS_SERVER="https://dns.Astram.com"

# ?¸ë“œ ?±ë¡
./register-node.sh 192.168.1.100 8333

# ?íƒœ ?•ì¸
./check-dns.sh
```

#### 2. ì§ì ‘ ?¤í¬ë¦½íŠ¸?ì„œ ?¬ìš©

```bash
# ??ì¤„ë¡œ ?¤í–‰
DNS_SERVER=http://dns.Astram.com:8053 ./register-node.sh 192.168.1.100 8333
DNS_SERVER=http://dns.Astram.com:8053 ./check-dns.sh
```

#### 3. .env ?Œì¼ ?¬ìš©

`.env` ?Œì¼??ë§Œë“¤?´ì„œ ê´€ë¦?

```bash
# .env ?Œì¼ ?ì„±
echo "DNS_SERVER=http://dns.Astram.com:8053" > .env

# ?¬ìš©????source .env
./register-node.sh 192.168.1.100 8333
```

### ?„ë©”???¤ì • ?ˆì‹œ (nginx)

HTTPSë¥??¬ìš©?˜ë ¤ë©?nginxë¥?ë¦¬ë²„???„ë¡?œë¡œ ?¤ì •:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name dns.Astram.com;

    ssl_certificate /etc/letsencrypt/live/dns.Astram.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dns.Astram.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8053;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## ë³´ì•ˆ ê³ ë ¤?¬í•­

1. **ë°©í™”ë²?*: ?„ìš”???¬íŠ¸ë§?ê°œë°©
2. **HTTPS**: ?„ë¡œ?•ì…˜ ?˜ê²½?ì„œ??ë¦¬ë²„???„ë¡??nginx) ?¬ìš© ê¶Œì¥
3. **Rate Limiting**: DDoS ë°©ì?ë¥??„í•œ ?”ì²­ ?œí•œ êµ¬í˜„ ê³ ë ¤
4. **?¸ì¦**: API ?”ë“œ?¬ì¸?¸ì— ?¸ì¦ ì¶”ê? ê³ ë ¤
5. **?„ë©”???¬ìš©**: ?„ë¡œ?•ì…˜?ì„œ??SSL/TLS ?¸ì¦?œì? ?¨ê»˜ ?„ë©”???¬ìš©

## ëª¨ë‹ˆ?°ë§

### ê¸°ë³¸ ëª¨ë‹ˆ?°ë§
```bash
# CPU, ë©”ëª¨ë¦??¬ìš©??top -p $(pgrep Astram-dns)

# ?¤íŠ¸?Œí¬ ?°ê²°
sudo netstat -an | grep 8053
```

### ë¡œê·¸ ëª¨ë‹ˆ?°ë§
```bash
# ?¤ì‹œê°?ë¡œê·¸
sudo journalctl -u Astram-dns -f

# ?ëŸ¬ ë¡œê·¸ë§?sudo journalctl -u Astram-dns -p err
```

