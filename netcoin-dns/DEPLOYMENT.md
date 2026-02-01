# Netcoin DNS 서버 배포 가이드

## 서버 정보
- **IP**: 161.33.19.183
- **OS**: Ubuntu 24.04
- **Port**: 8053

## 배포 방법

### 1. 서버에 파일 업로드

로컬에서 서버로 프로젝트 전체를 복사합니다:

```bash
# Windows에서 scp 사용 (PowerShell)
scp -r d:\coin\netcoin\netcoin-dns user@161.33.19.183:~/netcoin-dns

# 또는 rsync 사용 (WSL/Git Bash)
rsync -avz d:/coin/netcoin/netcoin-dns/ user@161.33.19.183:~/netcoin-dns/
```

### 2. 서버에 SSH 접속

```bash
ssh user@161.33.19.183
```

### 3. 배포 스크립트 실행

```bash
cd ~/netcoin-dns
chmod +x deploy.sh
./deploy.sh
```

이 스크립트는 자동으로:
- Rust 설치 (필요한 경우)
- 프로젝트 빌드
- systemd 서비스 설정
- 서비스 시작 및 활성화

### 4. 방화벽 설정

포트 8053을 열어줍니다:

```bash
# UFW 사용하는 경우
sudo ufw allow 8053/tcp

# iptables 사용하는 경우
sudo iptables -A INPUT -p tcp --dport 8053 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

## 노드 등록 방법

### 자신의 노드를 DNS 서버에 등록

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

### 예시 (로컬 노드 등록)

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

## API 엔드포인트

### 헬스 체크
```bash
curl http://161.33.19.183:8053/health
```

### 노드 목록 조회
```bash
# 모든 노드
curl http://161.33.19.183:8053/nodes

# 최대 10개 노드
curl http://161.33.19.183:8053/nodes?limit=10

# 최소 높이 100 이상인 노드
curl http://161.33.19.183:8053/nodes?min_height=100
```

### 통계 조회
```bash
curl http://161.33.19.183:8053/stats
```

## 서비스 관리

### 상태 확인
```bash
sudo systemctl status netcoin-dns
```

### 로그 확인
```bash
# 실시간 로그
sudo journalctl -u netcoin-dns -f

# 최근 100줄
sudo journalctl -u netcoin-dns -n 100
```

### 서비스 재시작
```bash
sudo systemctl restart netcoin-dns
```

### 서비스 중지
```bash
sudo systemctl stop netcoin-dns
```

### 서비스 시작
```bash
sudo systemctl start netcoin-dns
```

## 노드에서 DNS 서버 사용하기

Netcoin 노드의 설정 파일에 DNS 서버 주소를 추가:

```toml
[network]
dns_servers = ["http://161.33.19.183:8053"]
```

또는 노드 시작 시 파라미터로 전달:

```bash
netcoin-node --dns-server http://161.33.19.183:8053
```

## 수동 빌드 및 실행 (배포 스크립트 사용하지 않는 경우)

### 빌드
```bash
cd ~/netcoin-dns
cargo build --release
```

### 실행
```bash
# 기본 설정으로 실행
./target/release/netcoin-dns

# 커스텀 포트와 최대 노드 유효 시간
./target/release/netcoin-dns --port 8053 --max-age 7200
```

## 트러블슈팅

### 포트가 이미 사용 중인 경우
```bash
# 포트 사용 확인
sudo netstat -tulpn | grep 8053

# 프로세스 종료
sudo kill -9 <PID>
```

### 서비스가 시작되지 않는 경우
```bash
# 상세 로그 확인
sudo journalctl -u netcoin-dns -n 50 --no-pager

# 서비스 파일 재로드
sudo systemctl daemon-reload
sudo systemctl restart netcoin-dns
```

### Rust가 설치되지 않는 경우
```bash
# 수동 설치
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

## 업데이트 방법

코드를 수정한 후:

```bash
# 로컬에서 서버로 업로드
scp -r d:\coin\netcoin\netcoin-dns user@161.33.19.183:~/netcoin-dns

# 서버에서
cd ~/netcoin-dns
cargo build --release
sudo cp target/release/netcoin-dns /usr/local/bin/
sudo systemctl restart netcoin-dns
```

## 도메인 사용하기

### 도메인 설정 후 사용 방법

도메인(예: dns.netcoin.com)을 설정한 후에는 IP 주소 대신 도메인을 사용할 수 있습니다.

#### 1. 환경 변수로 설정

```bash
# 환경 변수 설정
export DNS_SERVER="http://dns.netcoin.com:8053"

# 또는 HTTPS 사용
export DNS_SERVER="https://dns.netcoin.com"

# 노드 등록
./register-node.sh 192.168.1.100 8333

# 상태 확인
./check-dns.sh
```

#### 2. 직접 스크립트에서 사용

```bash
# 한 줄로 실행
DNS_SERVER=http://dns.netcoin.com:8053 ./register-node.sh 192.168.1.100 8333
DNS_SERVER=http://dns.netcoin.com:8053 ./check-dns.sh
```

#### 3. .env 파일 사용

`.env` 파일을 만들어서 관리:

```bash
# .env 파일 생성
echo "DNS_SERVER=http://dns.netcoin.com:8053" > .env

# 사용할 때
source .env
./register-node.sh 192.168.1.100 8333
```

### 도메인 설정 예시 (nginx)

HTTPS를 사용하려면 nginx를 리버스 프록시로 설정:

```nginx
server {
    listen 80;
    listen 443 ssl http2;
    server_name dns.netcoin.com;

    ssl_certificate /etc/letsencrypt/live/dns.netcoin.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dns.netcoin.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8053;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 보안 고려사항

1. **방화벽**: 필요한 포트만 개방
2. **HTTPS**: 프로덕션 환경에서는 리버스 프록시(nginx) 사용 권장
3. **Rate Limiting**: DDoS 방지를 위한 요청 제한 구현 고려
4. **인증**: API 엔드포인트에 인증 추가 고려
5. **도메인 사용**: 프로덕션에서는 SSL/TLS 인증서와 함께 도메인 사용

## 모니터링

### 기본 모니터링
```bash
# CPU, 메모리 사용량
top -p $(pgrep netcoin-dns)

# 네트워크 연결
sudo netstat -an | grep 8053
```

### 로그 모니터링
```bash
# 실시간 로그
sudo journalctl -u netcoin-dns -f

# 에러 로그만
sudo journalctl -u netcoin-dns -p err
```
