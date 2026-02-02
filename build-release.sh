#!/bin/bash
# NetCoin Release Build Script for Linux/macOS
# This script builds all components and packages them for distribution

set -e

# Colors
INFO='\033[0;36m'
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
NC='\033[0m'

echo -e "${INFO}ℹ️  NetCoin Release Builder${NC}"
echo ""

# Detect platform
case "$(uname -s)" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="macos";;
    *)          echo -e "${ERROR}❌ Unsupported platform$(NC)"; exit 1;;
esac

echo -e "${INFO}ℹ️  Detected platform: $PLATFORM${NC}"

# Clean previous release
RELEASE_DIR="release/$PLATFORM"
if [ -d "$RELEASE_DIR" ]; then
    echo -e "${INFO}ℹ️  Cleaning previous release...${NC}"
    rm -rf "$RELEASE_DIR"
fi

# Create release directory
echo -e "${INFO}ℹ️  Creating release directory...${NC}"
mkdir -p "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/config"

# Build all components in release mode
echo -e "${INFO}ℹ️  Building all components in release mode...${NC}"
cargo build --release

echo -e "${SUCCESS}✅ Build completed successfully!${NC}"

# Copy executables
echo -e "${INFO}ℹ️  Copying executables...${NC}"
EXECUTABLES=(
    "netcoin-node"
    "netcoin-dns"
    "netcoin-explorer"
    "wallet-cli"
)

for exe in "${EXECUTABLES[@]}"; do
    source="target/release/$exe"
    if [ -f "$source" ]; then
        cp "$source" "$RELEASE_DIR/$exe"
        chmod +x "$RELEASE_DIR/$exe"
        echo -e "${SUCCESS}✅ Copied $exe${NC}"
    else
        echo -e "${ERROR}❌ Missing: $exe${NC}"
    fi
done

# Create launcher script
echo -e "${INFO}ℹ️  Creating launcher script...${NC}"
cat > "$RELEASE_DIR/netcoin.sh" << 'LAUNCHER_EOF'
#!/bin/bash
# NetCoin Launcher for Linux/macOS
# Usage: ./netcoin.sh [node|dns|explorer|wallet] [args...]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPONENT="${1:-node}"
shift || true

case "$COMPONENT" in
    node)
        EXE="netcoin-node"
        ;;
    dns)
        EXE="netcoin-dns"
        ;;
    explorer)
        EXE="netcoin-explorer"
        ;;
    wallet)
        EXE="wallet-cli"
        ;;
    *)
        echo "Usage: $0 [node|dns|explorer|wallet] [args...]"
        exit 1
        ;;
esac

EXE_PATH="$SCRIPT_DIR/$EXE"

if [ ! -f "$EXE_PATH" ]; then
    echo "Error: $EXE not found"
    exit 1
fi

echo "Starting NetCoin $COMPONENT..."
"$EXE_PATH" "$@"
LAUNCHER_EOF

chmod +x "$RELEASE_DIR/netcoin.sh"

# Copy sample config
echo -e "${INFO}ℹ️  Creating sample configuration...${NC}"
cat > "$RELEASE_DIR/config/example.conf" << 'CONFIG_EOF'
# NetCoin Configuration Example
# Copy this file and modify as needed

# Node Settings
NODE_PORT=8333
P2P_PORT=8335

# DNS Server
DNS_PORT=8053

# Explorer
EXPLORER_PORT=3000

# Data Directory
# Linux/macOS: ~/.netcoin
DATA_DIR=~/.netcoin
CONFIG_EOF

# Create README
echo -e "${INFO}ℹ️  Creating README...${NC}"
cat > "$RELEASE_DIR/README.md" << README_EOF
# NetCoin for $PLATFORM

## Quick Start

1. Extract this archive to a folder
2. Open a terminal in this directory
3. Run a component:

\`\`\`bash
# Run blockchain node
./netcoin.sh node

# Run DNS server
./netcoin.sh dns

# Run blockchain explorer
./netcoin.sh explorer

# Run wallet CLI
./netcoin.sh wallet
\`\`\`

## Components

- **netcoin-node** - Main blockchain node (HTTP: 8333, P2P: 8335)
- **netcoin-dns** - DNS discovery server (Port: 8053)
- **netcoin-explorer** - Web-based blockchain explorer (Port: 3000)
- **wallet-cli** - Command-line wallet interface

## System Requirements

- $PLATFORM (64-bit)
- 4GB RAM minimum
- 10GB free disk space

## Data Directory

NetCoin stores blockchain data in: \`~/.netcoin\`

To reset the blockchain, delete this directory while no nodes are running.

## Configuration

See \`config/example.conf\` for configuration options.

## Support

For issues and documentation, visit: https://github.com/yourorg/netcoin
README_EOF

# Create version info
VERSION=$(grep '^version =' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
cat > "$RELEASE_DIR/VERSION.txt" << VERSION_EOF
NetCoin v$VERSION
Built: $(date '+%Y-%m-%d %H:%M:%S')
Platform: $PLATFORM x64
VERSION_EOF

echo -e "${SUCCESS}✅ Release package created successfully!${NC}"
echo ""
echo -e "${INFO}ℹ️  Release directory: $RELEASE_DIR${NC}"
echo -e "${INFO}ℹ️  To distribute: compress the folder and share the archive${NC}"
echo ""
echo -e "${INFO}ℹ️  Next steps:${NC}"
echo "  1. Test the executables in $RELEASE_DIR/"
echo "  2. Create a tarball: tar -czf netcoin-$PLATFORM-v$VERSION.tar.gz -C release $PLATFORM"
echo "  3. Share the tarball with users"
