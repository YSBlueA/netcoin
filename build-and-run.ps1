#!/usr/bin/env pwsh
# Astram Build and Run Script for Windows/PowerShell
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
function Write-Info { Write-Host "INFO  $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "OK    $args" -ForegroundColor Green }
function Write-Error { Write-Host "ERROR $args" -ForegroundColor Red }

# Build configuration
$BuildMode = if ($Release) { "release" } else { "debug" }
$BuildFlag = if ($Release) { "--release" } else { "" }
$TargetDir = "target/$BuildMode"

Write-Info "Astram Build & Run Script"
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
            Build-Component "Astram Node" "."
            Run-Component "Astram Node" "Astram-node.exe"
        }
        'dns' {
            Build-Component "DNS Server" "Astram-dns"
            Run-Component "DNS Server" "Astram-dns.exe"
        }
        'explorer' {
            Build-Component "Explorer" "explorer"
            Run-Component "Explorer" "Astram-explorer.exe"
        }
        'wallet' {
            Build-Component "Wallet CLI" "wallet-cli"
            Run-Component "Wallet CLI" "wallet-cli.exe"
        }
        'all' {
            Write-Info "Building all components..."
            Build-Component "Astram Core" "."
            Build-Component "DNS Server" "Astram-dns"
            Build-Component "Explorer" "explorer"
            Build-Component "Wallet CLI" "wallet-cli"
            Write-Success "All components built successfully!"
            Write-Host ""
            Write-Info "To run components:"
            Write-Host "  Node:     .\$TargetDir\Astram-node.exe"
            Write-Host "  DNS:      .\$TargetDir\Astram-dns.exe"
            Write-Host "  Explorer: .\$TargetDir\Astram-explorer.exe"
            Write-Host "  Wallet:   .\$TargetDir\wallet-cli.exe"
        }
    }
} catch {
    Write-Error "Operation failed: $_"
    exit 1
}

