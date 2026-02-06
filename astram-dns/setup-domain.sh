#!/bin/bash
# ?ÑÎ©î???§Ï†ï Î∞?SSL ?∏Ï¶ù???êÎèô ?§Ï†ï ?§ÌÅ¨Î¶ΩÌä∏

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <domain_name> [email]"
    echo "Example: $0 dns.Astram.com admin@Astram.com"
    exit 1
fi

DOMAIN=$1
EMAIL=${2:-""}

echo "=== Setting up domain: $DOMAIN ==="

# Nginx ?§Ïπò ?ïÏù∏
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo apt update
    sudo apt install -y nginx
fi

# Certbot ?§Ïπò ?ïÏù∏
if ! command -v certbot &> /dev/null; then
    echo "Installing certbot..."
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
fi

# Nginx ?§Ï†ï ?åÏùº ?ùÏÑ± (?ÑÏãú - SSL ?∏Ï¶ù??Î∞úÍ∏â ??
echo "Creating temporary nginx configuration..."
sudo tee /etc/nginx/sites-available/Astram-dns > /dev/null <<EOF
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

# ?¨Î≥ºÎ¶?ÎßÅÌÅ¨ ?ùÏÑ±
sudo ln -sf /etc/nginx/sites-available/Astram-dns /etc/nginx/sites-enabled/

# Nginx ?§Ï†ï ?åÏä§??Î∞??¨Ïãú??echo "Testing nginx configuration..."
sudo nginx -t
sudo systemctl restart nginx

# SSL ?∏Ï¶ù??Î∞úÍ∏â
echo "Obtaining SSL certificate..."
if [ -n "$EMAIL" ]; then
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email $EMAIL
else
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --register-unsafely-without-email
fi

# ÏµúÏ¢Ö Nginx ?§Ï†ï ?åÏùºÎ°?ÍµêÏ≤¥
echo "Updating nginx configuration with SSL..."
sudo tee /etc/nginx/sites-available/Astram-dns > /dev/null <<EOF
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

# Nginx ?¨Ïãú??sudo nginx -t
sudo systemctl restart nginx

# Î∞©ÌôîÎ≤??§Ï†ï
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

