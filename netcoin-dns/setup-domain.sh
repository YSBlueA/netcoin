#!/bin/bash
# 도메인 설정 및 SSL 인증서 자동 설정 스크립트

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <domain_name> [email]"
    echo "Example: $0 dns.netcoin.com admin@netcoin.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-""}

echo "=== Setting up domain: $DOMAIN ==="

# Nginx 설치 확인
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# Certbot 설치 확인
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Nginx 설정 파일 생성 (임시 - SSL 인증서 발급 전)
echo "Creating temporary nginx configuration..."
sudo tee /etc/nginx/sites-available/netcoin-dns > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        proxy_pass http://127.0.0.1:8053;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# 심볼릭 링크 생성
sudo ln -sf /etc/nginx/sites-available/netcoin-dns /etc/nginx/sites-enabled/

# Nginx 설정 테스트 및 재시작
echo "Testing nginx configuration..."
sudo nginx -t
sudo systemctl restart nginx

# SSL 인증서 발급
echo "Obtaining SSL certificate..."
if [ -n "$EMAIL" ]; then
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
else
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email
fi

# 최종 Nginx 설정 파일로 교체
echo "Updating nginx configuration with SSL..."
sudo tee /etc/nginx/sites-available/netcoin-dns > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    location / {
        proxy_pass http://127.0.0.1:8053;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Nginx 재시작
sudo nginx -t
sudo systemctl restart nginx

# 방화벽 설정
if command -v ufw &> /dev/null; then
    echo "Configuring firewall..."
    sudo ufw allow 'Nginx Full'
    sudo ufw allow 8053/tcp
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Your DNS server is now accessible at:"
echo "  HTTP:  http://$DOMAIN (redirects to HTTPS)"
echo "  HTTPS: https://$DOMAIN"
echo ""
echo "To use the domain in scripts:"
echo "  export DNS_SERVER=https://$DOMAIN"
echo "  ./register-node.sh 192.168.1.100 8333"
echo ""
echo "SSL certificate will auto-renew via certbot."
echo "Check renewal: sudo certbot renew --dry-run"
