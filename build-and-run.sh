#!/bin/bash
# NetCoin Build and Run Script for Linux/macOS
# Usage: ./build-and-run.sh [node|dns|explorer|wallet|all] [--release] [--skip-build]

set -e

# Colors
INFO='\033[0;36m'
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
NC='\033[0m' # No Color

# Default values
COMPONENT="${1:-node}"
BUILD_MODE="debug"
BUILD_FLAG=""
SKIP_BUILD=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --release)
            BUILD_MODE="release"
            BUILD_FLAG="--release"
            ;;
        --skip-build)
            SKIP_BUILD=true
            ;;
    esac
done

TARGET_DIR="target/$BUILD_MODE"

echo -e "${INFO}ℹ️  NetCoin Build & Run Script${NC}"
echo -e "${INFO}ℹ️  Component: $COMPONENT | Mode: $BUILD_MODE${NC}"
echo ""

# Build function
build_component() {
    local name=$1
    local path=$2
    
    if [ "$SKIP_BUILD" = true ]; then
        echo -e "${INFO}ℹ️  Skipping build for $name${NC}"
        return
    fi
    
    echo -e "${INFO}ℹ️  Building $name...${NC}"
    cd "$path"
    cargo build $BUILD_FLAG
    cd - > /dev/null
    echo -e "${SUCCESS}✅ $name built successfully${NC}"
}

# Run function
run_component() {
    local name=$1
    local executable=$2
    local args="${3:-}"
    
    echo -e "${INFO}ℹ️  Starting $name...${NC}"
    local exe_path="$TARGET_DIR/$executable"
    
    if [ ! -f "$exe_path" ]; then
        echo -e "${ERROR}❌ $name executable not found at $exe_path${NC}"
        echo -e "${INFO}ℹ️  Run without --skip-build flag to build first${NC}"
        return 1
    fi
    
    echo -e "${SUCCESS}✅ Running $name from $exe_path${NC}"
    if [ -n "$args" ]; then
        "$exe_path" $args
    else
        "$exe_path"
    fi
}

# Main execution
case "$COMPONENT" in
    node)
        build_component "NetCoin Node" "."
        run_component "NetCoin Node" "netcoin-node"
        ;;
    dns)
        build_component "DNS Server" "netcoin-dns"
        run_component "DNS Server" "netcoin-dns"
        ;;
    explorer)
        build_component "Explorer" "explorer"
        run_component "Explorer" "netcoin-explorer"
        ;;
    wallet)
        build_component "Wallet CLI" "wallet-cli"
        run_component "Wallet CLI" "wallet-cli"
        ;;
    all)
        echo -e "${INFO}ℹ️  Building all components...${NC}"
        build_component "NetCoin Core" "."
        build_component "DNS Server" "netcoin-dns"
        build_component "Explorer" "explorer"
        build_component "Wallet CLI" "wallet-cli"
        echo -e "${SUCCESS}✅ All components built successfully!${NC}"
        echo ""
        echo -e "${INFO}ℹ️  To run components:${NC}"
        echo "  Node:     ./$TARGET_DIR/netcoin-node"
        echo "  DNS:      ./$TARGET_DIR/netcoin-dns"
        echo "  Explorer: ./$TARGET_DIR/netcoin-explorer"
        echo "  Wallet:   ./$TARGET_DIR/wallet-cli"
        ;;
    *)
        echo -e "${ERROR}❌ Invalid component: $COMPONENT${NC}"
        echo "Usage: $0 [node|dns|explorer|wallet|all] [--release] [--skip-build]"
        exit 1
        ;;
esac
