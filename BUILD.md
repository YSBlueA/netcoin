# Astram Build Guide

This guide explains how to build and run Astram on different platforms.

## Prerequisites

- **Rust** 1.70 or later ([Install Rust](https://rustup.rs/))
- **Git** (for cloning the repository)

## Platform-Specific Instructions

### Windows

1. Open PowerShell in the project directory
2. Run the build script:

```powershell
# Build and run node (debug mode)
.\build-and-run.ps1 node

# Build and run in release mode (optimized)
.\build-and-run.ps1 node -Release

# Build all components without running
.\build-and-run.ps1 all -Release

# Run without rebuilding (if already built)
.\build-and-run.ps1 node -SkipBuild
```

### Linux / macOS

1. Open a terminal in the project directory
2. Make the script executable (first time only):

```bash
chmod +x build-and-run.sh
```

3. Run the build script:

```bash
# Build and run node (debug mode)
./build-and-run.sh node

# Build and run in release mode (optimized)
./build-and-run.sh node --release

# Build all components without running
./build-and-run.sh all --release

# Run without rebuilding (if already built)
./build-and-run.sh node --skip-build
```

## Available Components

You can build and run different components:

- **node** - Main blockchain node (default)
- **dns** - DNS discovery server
- **explorer** - Blockchain explorer with web interface
- **wallet** - Command-line wallet
- **all** - Build all components

### Examples

**Run DNS Server:**

```bash
# Windows
.\build-and-run.ps1 dns -Release

# Linux/macOS
./build-and-run.sh dns --release
```

**Run Explorer:**

```bash
# Windows
.\build-and-run.ps1 explorer -Release

# Linux/macOS
./build-and-run.sh explorer --release
```

**Run Wallet CLI:**

```bash
# Windows
.\build-and-run.ps1 wallet

# Linux/macOS
./build-and-run.sh wallet
```

## Manual Build

If you prefer to build manually with cargo:

```bash
# Build all components in release mode
cargo build --release

# Build specific component
cd node && cargo build --release
cd Astram-dns && cargo build --release
cd explorer && cargo build --release
cd wallet-cli && cargo build --release

# Run executables
./target/release/Astram-node
./target/release/Astram-dns
./target/release/Astram-explorer
./target/release/wallet-cli
```

## Running a Full Network

To run a complete local network:

**Terminal 1 - DNS Server:**

```bash
# Windows
.\build-and-run.ps1 dns -Release

# Linux/macOS
./build-and-run.sh dns --release
```

**Terminal 2 - First Node:**

```bash
# Windows
.\build-and-run.ps1 node -Release

# Linux/macOS
./build-and-run.sh node --release
```

**Terminal 3 - Explorer (Optional):**

```bash
# Windows
.\build-and-run.ps1 explorer -Release

# Linux/macOS
./build-and-run.sh explorer --release
```

## Default Ports

- **Node HTTP RPC**: 19533
- **Node P2P**: 8335
- **DNS Server**: 8053
- **Explorer**: 3000

## Build Outputs

Executables are located in:

- **Debug builds**: `target/debug/`
- **Release builds**: `target/release/`

Release builds are optimized and recommended for production use.

## Troubleshooting

### Database Lock Errors

If you encounter "lock hold by current process" errors:

1. Stop all running nodes
2. Wait 1-2 seconds for file handles to release
3. Restart the node

### Port Already in Use

If a port is already in use, stop the existing process:

**Windows:**

```powershell
# Find process using port 19533
netstat -ano | findstr :19533

# Kill process by PID
taskkill /PID <PID> /F
```

**Linux/macOS:**

```bash
# Find and kill process using port 19533
lsof -ti:19533 | xargs kill -9
```

### Missing Dependencies

Ensure you have the latest Rust toolchain:

```bash
rustup update stable
```

## Clean Build

To remove all build artifacts and start fresh:

```bash
cargo clean
```

Then rebuild using the scripts above.

