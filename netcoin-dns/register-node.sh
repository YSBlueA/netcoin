#!/bin/bash
# 노드를 Netcoin DNS 서버에 등록하는 스크립트

# DNS 서버 주소 (환경 변수 또는 기본값 사용)
# 사용 예: DNS_SERVER=http://dns.netcoin.com:8053 ./register-node.sh ...
DNS_SERVER=${DNS_SERVER:-"http://161.33.19.183:8053"}

# 파라미터 확인
if [ $# -lt 2 ]; then
    echo "Usage: $0 <node_address> <node_port> [version] [height]"
    echo "Example: $0 192.168.1.100 8333 0.1.0 1"
    exit 1
fi

NODE_ADDRESS=$1
NODE_PORT=$2
VERSION=${3:-"0.1.0"}
HEIGHT=${4:-0}

echo "Registering node to DNS server..."
echo "DNS Server: $DNS_SERVER"
echo "Node: $NODE_ADDRESS:$NODE_PORT"
echo "Version: $VERSION"
echo "Height: $HEIGHT"

response=$(curl -s -X POST $DNS_SERVER/register \
  -H "Content-Type: application/json" \
  -d "{
    \"address\": \"$NODE_ADDRESS\",
    \"port\": $NODE_PORT,
    \"version\": \"$VERSION\",
    \"height\": $HEIGHT
  }")

echo ""
echo "Response:"
echo $response | jq . 2>/dev/null || echo $response

# 등록 확인
echo ""
echo "Checking registered nodes..."
curl -s $DNS_SERVER/nodes | jq . 2>/dev/null || curl -s $DNS_SERVER/nodes
