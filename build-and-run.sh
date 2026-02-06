#!/bin/bash
# Astram Build and Run Script for Linux/macOS
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

echo -e "${INFO} Astram Build & Run Script${NC}"
echo -e "${INFO} Component: $COMPONENT | Mode: $BUILD_MODE${NC}"
echo ""

# Build function
build_component() {
    local name=$1
    local path=$2
    
    if [ "$SKIP_BUILD" = true ]; then
        echo -e "${INFO} Skipping build for $name${NC}"
        return
    fi
    
    echo -e "${INFO} Building $name...${NC}"
    cd "$path"
    cargo build $BUILD_FLAG
    cd - > /dev/null
    echo -e "${SUCCESS}??$name built successfully${NC}"
}

# Run function
run_component() {
    local name=$1
    local executable=$2
    local args="${3:-}"
    
    echo -e "${INFO} Starting $name...${NC}"
    local exe_path="$TARGET_DIR/$executable"
    
    if [ ! -f "$exe_path" ]; then
        echo -e "${ERROR}$name executable not found at $exe_path${NC}"
        echo -e "${INFO} Run without --skip-build flag to build first${NC}"
        return 1
    fi
    
    echo -e "${SUCCESS}??Running $name from $exe_path${NC}"
    if [ -n "$args" ]; then
        "$exe_path" $args
    else
        "$exe_path"
    fi
}

# Main execution
case "$COMPONENT" in
    node)
        build_component "Astram Node" "."
        run_component "Astram Node" "Astram-node"
        ;;
    dns)
        build_component "DNS Server" "Astram-dns"
        run_component "DNS Server" "Astram-dns"
        ;;
    explorer)
        build_component "Explorer" "explorer"
        run_component "Explorer" "Astram-explorer"
        ;;
    wallet)
        build_component "Wallet CLI" "wallet-cli"
        run_component "Wallet CLI" "wallet-cli"
        ;;
    all)
        echo -e "${INFO}?�️  Building all components...${NC}"
        build_component "Astram Core" "."
        build_component "DNS Server" "Astram-dns"
        build_component "Explorer" "explorer"
        build_component "Wallet CLI" "wallet-cli"
        echo -e "${SUCCESS}??All components built successfully!${NC}"
        echo ""
        echo -e "${INFO}?�️  To run components:${NC}"
        echo "  Node:     ./$TARGET_DIR/Astram-node"
        echo "  DNS:      ./$TARGET_DIR/Astram-dns"
        echo "  Explorer: ./$TARGET_DIR/Astram-explorer"
        echo "  Wallet:   ./$TARGET_DIR/wallet-cli"
        ;;
    *)
        echo -e "${ERROR}??Invalid component: $COMPONENT${NC}"
        echo "Usage: $0 [node|dns|explorer|wallet|all] [--release] [--skip-build]"
        exit 1
        ;;
esac

