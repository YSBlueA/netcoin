#!/bin/bash
# Astram Release Build Script for Linux/macOS
# This script builds all components and packages them for distribution

set -e

# Colors
INFO='\033[0;36m'
SUCCESS='\033[0;32m'
ERROR='\033[0;31m'
NC='\033[0m'

echo -e "${INFO}INFO  Astram Release Builder${NC}"
echo ""

# Detect platform
case "$(uname -s)" in
    Linux*)     PLATFORM="linux";;
    Darwin*)    PLATFORM="macos";;
    *)          echo -e "${ERROR}ERROR Unsupported platform$(NC)"; exit 1;;
esac

echo -e "${INFO}INFO  Detected platform: $PLATFORM${NC}"

# Clean previous release
RELEASE_DIR="release/$PLATFORM"
if [ -d "$RELEASE_DIR" ]; then
    echo -e "${INFO}INFO  Cleaning previous release...${NC}"
    rm -rf "$RELEASE_DIR"
fi

# Create release directory
echo -e "${INFO}INFO  Creating release directory...${NC}"
mkdir -p "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR/config"

# Build all components in release mode
echo -e "${INFO}INFO  Building all components in release mode...${NC}"
cargo build --release

echo -e "${SUCCESS}OK    Build completed successfully!${NC}"

# Copy executables
echo -e "${INFO}INFO  Copying executables...${NC}"
EXECUTABLES=(
    "Astram-node"
    "Astram-dns"
    "Astram-explorer"
    "wallet-cli"
)

for exe in "${EXECUTABLES[@]}"; do
    source="target/release/$exe"
    if [ -f "$source" ]; then
        cp "$source" "$RELEASE_DIR/$exe"
        chmod +x "$RELEASE_DIR/$exe"
        echo -e "${SUCCESS}OK    Copied $exe${NC}"
    else
        echo -e "${ERROR}ERROR Missing: $exe${NC}"
    fi
done

# Create launcher script
echo -e "${INFO}INFO  Creating launcher script...${NC}"
cat > "$RELEASE_DIR/Astram.sh" << 'LAUNCHER_EOF'
#!/bin/bash
# Astram Launcher for Linux/macOS
# Usage: ./Astram.sh [node|dns|explorer|wallet] [args...]

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
COMPONENT="${1:-node}"
shift || true

case "$COMPONENT" in
    node)
        EXE="Astram-node"
        ;;
    dns)
        EXE="Astram-dns"
        ;;
    explorer)
        EXE="Astram-explorer"
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

echo "Starting Astram $COMPONENT..."
"$EXE_PATH" "$@"
LAUNCHER_EOF

chmod +x "$RELEASE_DIR/Astram.sh"

# Copy sample config
echo -e "${INFO}INFO  Creating sample configuration...${NC}"
cat > "$RELEASE_DIR/config/example.conf" << 'CONFIG_EOF'
# Astram Configuration Example
# Copy this file and modify as needed

# Node Settings
NODE_PORT=8333
P2P_PORT=8335

# DNS Server
DNS_PORT=8053

# Explorer
EXPLORER_PORT=3000

# Data Directory
# Linux/macOS: ~/.Astram
DATA_DIR=~/.Astram
CONFIG_EOF

# Create README
echo -e "${INFO}INFO  Creating README...${NC}"
cat > "$RELEASE_DIR/README.md" << README_EOF
# Astram for $PLATFORM

## Quick Start

1. Extract this archive to a folder
2. Open a terminal in this directory
3. Run a component:

\`\`\`bash
# Run blockchain node
./Astram.sh node

# Run DNS server
./Astram.sh dns

# Run blockchain explorer
./Astram.sh explorer

# Run wallet CLI
./Astram.sh wallet
\`\`\`

## Components

- **Astram-node** - Main blockchain node (HTTP: 8333, P2P: 8335)
- **Astram-dns** - DNS discovery server (Port: 8053)
- **Astram-explorer** - Web-based blockchain explorer (Port: 3000)
- **wallet-cli** - Command-line wallet interface

## System Requirements

- $PLATFORM (64-bit)
- 4GB RAM minimum
- 10GB free disk space

## Data Directory

Astram stores blockchain data in: \`~/.Astram\`

To reset the blockchain, delete this directory while no nodes are running.

## Configuration

See \`config/example.conf\` for configuration options.

## Support

For issues and documentation, visit: https://github.com/yourorg/Astram
README_EOF

# Create version info
VERSION=$(grep '^version =' Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
cat > "$RELEASE_DIR/VERSION.txt" << VERSION_EOF
Astram v$VERSION
Built: $(date '+%Y-%m-%d %H:%M:%S')
Platform: $PLATFORM x64
VERSION_EOF

echo -e "${SUCCESS}OK    Release package created successfully!${NC}"
echo ""
echo -e "${INFO}INFO  Release directory: $RELEASE_DIR${NC}"
echo -e "${INFO}INFO  To distribute: compress the folder and share the archive${NC}"
echo ""
echo -e "${INFO}INFO  Next steps:${NC}"
echo "  1. Test the executables in $RELEASE_DIR/"
echo "  2. Create a tarball: tar -czf Astram-$PLATFORM-v$VERSION.tar.gz -C release $PLATFORM"
echo "  3. Share the tarball with users"

