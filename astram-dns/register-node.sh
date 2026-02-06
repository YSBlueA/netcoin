#!/bin/bash
# ?Έλ“λ¥?Astram DNS ?λ²„???±λ΅?λ” ?¤ν¬λ¦½νΈ

# DNS ?λ²„ μ£Όμ† (?κ²½ λ³€???λ” κΈ°λ³Έκ°??¬μ©)
# ?¬μ© ?? DNS_SERVER=http://dns.Astram.com:8053 ./register-node.sh ...
DNS_SERVER=${DNS_SERVER:-"http://161.33.19.183:8053"}

# ?λΌλ―Έν„° ?•μΈ
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

# ?±λ΅ ?•μΈ
echo ""
echo "Checking registered nodes..."
curl -s $DNS_SERVER/nodes | jq . 2>/dev/null || curl -s $DNS_SERVER/nodes

