#!/usr/bin/env pwsh
# NetCoin Build and Run Script for Windows/PowerShell
# Usage: .\build-and-run.ps1 [node|dns|explorer|wallet|all]

param(
    [Parameter(Position=0)]
    [ValidateSet('node', 'dns', 'explorer', 'wallet', 'all')]
    [string]$Component = 'node',
    
    [Parameter()]
    [switch]$Release,
    
    [Parameter()]
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }

# Build configuration
$BuildMode = if ($Release) { "release" } else { "debug" }
$BuildFlag = if ($Release) { "--release" } else { "" }
$TargetDir = "target/$BuildMode"

Write-Info "NetCoin Build & Run Script"
Write-Info "Component: $Component | Mode: $BuildMode"
Write-Host ""

# Build function
function Build-Component {
    param([string]$Name, [string]$Path)
    
    if ($SkipBuild) {
        Write-Info "Skipping build for $Name"
        return
    }
    
    Write-Info "Building $Name..."
    Push-Location $Path
    try {
        if ($Release) {
            cargo build --release
        } else {
            cargo build
        }
        Write-Success "$Name built successfully"
    } catch {
        Write-Error "Failed to build $Name"
        throw
    } finally {
        Pop-Location
    }
}

# Run function
function Run-Component {
    param([string]$Name, [string]$Executable, [string]$Args = "")
    
    Write-Info "Starting $Name..."
    $ExePath = Join-Path $TargetDir $Executable
    
    if (-not (Test-Path $ExePath)) {
        Write-Error "$Name executable not found at $ExePath"
        Write-Info "Run without -SkipBuild flag to build first"
        return
    }
    
    Write-Success "Running $Name from $ExePath"
    if ($Args) {
        & $ExePath $Args.Split(" ")
    } else {
        & $ExePath
    }
}

# Main execution
try {
    switch ($Component) {
        'node' {
            Build-Component "NetCoin Node" "."
            Run-Component "NetCoin Node" "netcoin-node.exe"
        }
        'dns' {
            Build-Component "DNS Server" "netcoin-dns"
            Run-Component "DNS Server" "netcoin-dns.exe"
        }
        'explorer' {
            Build-Component "Explorer" "explorer"
            Run-Component "Explorer" "netcoin-explorer.exe"
        }
        'wallet' {
            Build-Component "Wallet CLI" "wallet-cli"
            Run-Component "Wallet CLI" "wallet-cli.exe"
        }
        'all' {
            Write-Info "Building all components..."
            Build-Component "NetCoin Core" "."
            Build-Component "DNS Server" "netcoin-dns"
            Build-Component "Explorer" "explorer"
            Build-Component "Wallet CLI" "wallet-cli"
            Write-Success "All components built successfully!"
            Write-Host ""
            Write-Info "To run components:"
            Write-Host "  Node:     .\$TargetDir\netcoin-node.exe"
            Write-Host "  DNS:      .\$TargetDir\netcoin-dns.exe"
            Write-Host "  Explorer: .\$TargetDir\netcoin-explorer.exe"
            Write-Host "  Wallet:   .\$TargetDir\wallet-cli.exe"
        }
    }
} catch {
    Write-Error "Operation failed: $_"
    exit 1
}
