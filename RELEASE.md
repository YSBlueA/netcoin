# NetCoin Release Guide

This guide explains how to build and package NetCoin releases for distribution.

## Overview

NetCoin supports three platforms:

- **Windows** (x64)
- **Linux** (x64)
- **macOS** (x64/arm64)

Each platform requires building on that specific OS (no cross-compilation).

## Build Scripts

- `build-release.ps1` - Windows release builder
- `build-release.sh` - Linux/macOS release builder
- `build-all-releases.ps1` - Helper script for coordinating builds

## Building Releases

### Windows

1. Open PowerShell in the project directory
2. Run the release builder:

```powershell
.\build-release.ps1
```

3. Create distribution archive:

```powershell
$version = "0.1.0"  # Update to match Cargo.toml
Compress-Archive -Path release\windows\* -DestinationPath "netcoin-windows-v$version.zip"
```

**Output:** `release/windows/` containing:

- `netcoin-node.exe`
- `netcoin-dns.exe`
- `netcoin-explorer.exe`
- `wallet-cli.exe`
- `netcoin.ps1` (launcher)
- `README.md`
- `VERSION.txt`
- `config/example.conf`

### Linux

1. Open a terminal in the project directory
2. Make the script executable:

```bash
chmod +x build-release.sh
```

3. Run the release builder:

```bash
./build-release.sh
```

4. Create distribution archive:

```bash
VERSION="0.1.0"  # Update to match Cargo.toml
tar -czf "netcoin-linux-v$VERSION.tar.gz" -C release linux
```

**Output:** `release/linux/` containing:

- `netcoin-node`
- `netcoin-dns`
- `netcoin-explorer`
- `wallet-cli`
- `netcoin.sh` (launcher)
- `README.md`
- `VERSION.txt`
- `config/example.conf`

### macOS

Same as Linux, but output goes to `release/macos/`:

```bash
chmod +x build-release.sh
./build-release.sh

VERSION="0.1.0"
tar -czf "netcoin-macos-v$VERSION.tar.gz" -C release macos
```

## Release Structure

```
release/
├── windows/
│   ├── netcoin.ps1              # Launcher script
│   ├── netcoin-node.exe
│   ├── netcoin-dns.exe
│   ├── netcoin-explorer.exe
│   ├── wallet-cli.exe
│   ├── README.md
│   ├── VERSION.txt
│   └── config/
│       └── example.conf
├── linux/
│   ├── netcoin.sh               # Launcher script
│   ├── netcoin-node
│   ├── netcoin-dns
│   ├── netcoin-explorer
│   ├── wallet-cli
│   ├── README.md
│   ├── VERSION.txt
│   └── config/
│       └── example.conf
└── macos/
    ├── netcoin.sh
    ├── netcoin-node
    ├── netcoin-dns
    ├── netcoin-explorer
    ├── wallet-cli
    ├── README.md
    ├── VERSION.txt
    └── config/
        └── example.conf
```

## Distribution Workflow

### Complete Release Process

1. **Update version** in `Cargo.toml`:

   ```toml
   [package]
   version = "0.2.0"
   ```

2. **Build on Windows machine:**

   ```powershell
   .\build-release.ps1
   Compress-Archive -Path release\windows\* -DestinationPath netcoin-windows-v0.2.0.zip
   ```

3. **Build on Linux machine:**

   ```bash
   ./build-release.sh
   tar -czf netcoin-linux-v0.2.0.tar.gz -C release linux
   ```

4. **Build on macOS machine:**

   ```bash
   ./build-release.sh
   tar -czf netcoin-macos-v0.2.0.tar.gz -C release macos
   ```

5. **Create GitHub Release:**
   - Tag: `v0.2.0`
   - Title: `NetCoin v0.2.0`
   - Upload all three archives
   - Add release notes

### Quick Build (Current Platform Only)

```bash
# Run on any platform
pwsh build-all-releases.ps1
```

This builds for your current platform and shows next steps.

## User Instructions

Users download the appropriate archive for their platform and extract it.

### Windows Users

```powershell
# Extract ZIP file
Expand-Archive -Path netcoin-windows-v0.2.0.zip -DestinationPath netcoin

# Navigate to folder
cd netcoin

# Run a component
.\netcoin.ps1 node
.\netcoin.ps1 dns
.\netcoin.ps1 explorer
.\netcoin.ps1 wallet
```

### Linux/macOS Users

```bash
# Extract tarball
tar -xzf netcoin-linux-v0.2.0.tar.gz
cd linux

# Make launcher executable
chmod +x netcoin.sh

# Run a component
./netcoin.sh node
./netcoin.sh dns
./netcoin.sh explorer
./netcoin.sh wallet
```

## Testing Releases

Before distribution, test each platform package:

1. Extract on a clean system
2. Run each component:
   ```bash
   ./netcoin.sh node      # Should start node successfully
   ./netcoin.sh dns       # Should start DNS server
   ./netcoin.sh explorer  # Should start explorer
   ./netcoin.sh wallet    # Should show wallet CLI
   ```
3. Verify network connectivity between components
4. Check data directory creation (`~/.netcoin` or `%USERPROFILE%\.netcoin`)

## Automated Release Checklist

- [ ] Update version in `Cargo.toml`
- [ ] Update `CHANGELOG.md` with release notes
- [ ] Build Windows release
- [ ] Build Linux release
- [ ] Build macOS release
- [ ] Test all three packages
- [ ] Create Git tag (`git tag v0.2.0`)
- [ ] Push tag (`git push origin v0.2.0`)
- [ ] Create GitHub release
- [ ] Upload Windows ZIP
- [ ] Upload Linux tarball
- [ ] Upload macOS tarball
- [ ] Announce release

## File Sizes (Approximate)

- Windows release: ~20-30 MB (compressed)
- Linux release: ~15-25 MB (compressed)
- macOS release: ~15-25 MB (compressed)

Release builds are optimized and smaller than debug builds.

## Troubleshooting

### Build fails on release mode

Try cleaning first:

```bash
cargo clean
```

### Missing executables in release folder

Ensure all workspace members build:

```bash
cargo build --release --workspace
```

### Permission denied on Linux/macOS

Make scripts executable:

```bash
chmod +x build-release.sh
chmod +x release/linux/netcoin.sh
```

## Advanced: CI/CD Integration

For automated builds on GitHub Actions, see `.github/workflows/release.yml` (create this for automation).

Example workflow:

- Trigger on tag push (`v*`)
- Build on `windows-latest`, `ubuntu-latest`, `macos-latest`
- Upload artifacts to GitHub Release automatically
