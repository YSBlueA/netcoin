#!/bin/bash
# Astram DNS Server Deployment Script for Ubuntu 24.04

set -e

echo "=== Astram DNS Server Deployment ==="

# Install Rust if not installed
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Build the project
echo "Building Astram-dns..."
cargo build --release

# Create systemd service directory if needed
echo "Setting up systemd service..."

# Copy binary to /usr/local/bin
sudo cp target/release/Astram-dns /usr/local/bin/
sudo chmod +x /usr/local/bin/Astram-dns

# Create systemd service file
sudo tee /etc/systemd/system/Astram-dns.service > /dev/null <<EOF
[Unit]
Description=Astram DNS Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/Astram-dns --port 8053 --max-age 3600
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
sudo systemctl daemon-reload
sudo systemctl enable Astram-dns.service
sudo systemctl start Astram-dns.service

echo "=== Deployment Complete ==="
echo "Service status:"
sudo systemctl status Astram-dns.service --no-pager

echo ""
echo "Useful commands:"
echo "  Check status: sudo systemctl status Astram-dns"
echo "  View logs: sudo journalctl -u Astram-dns -f"
echo "  Restart: sudo systemctl restart Astram-dns"
echo "  Stop: sudo systemctl stop Astram-dns"
echo ""
echo "DNS Server will be available at:"
echo "  http://161.33.19.183:8053"
echo "  Health check: http://161.33.19.183:8053/health"
echo "  Node stats: http://161.33.19.183:8053/stats"

