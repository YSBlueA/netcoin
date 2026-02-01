#!/bin/bash
# DNS 서버 상태 확인 스크립트

# DNS 서버 주소 (환경 변수 또는 기본값 사용)
# 사용 예: DNS_SERVER=http://dns.netcoin.com:8053 ./check-dns.sh
DNS_SERVER=${DNS_SERVER:-"http://161.33.19.183:8053"}

echo "=== Netcoin DNS Server Status ==="
echo ""

# Health check
echo "1. Health Check:"
curl -s $DNS_SERVER/health | jq . 2>/dev/null || curl -s $DNS_SERVER/health
echo ""
echo ""

# Stats
echo "2. Statistics:"
curl -s $DNS_SERVER/stats | jq . 2>/dev/null || curl -s $DNS_SERVER/stats
echo ""
echo ""

# Nodes
echo "3. Registered Nodes:"
curl -s $DNS_SERVER/nodes | jq . 2>/dev/null || curl -s $DNS_SERVER/nodes
echo ""
