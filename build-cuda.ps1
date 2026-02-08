#!/usr/bin/env pwsh
# CUDA 마이너 자동 빌드 및 실행 스크립트
# GPU를 자동 감지하여 적절한 아키텍처로 빌드합니다.

param(
    [switch]$SkipBuild,
    [switch]$Release = $true
)

Write-Host "=== CUDA Miner Build Script ===" -ForegroundColor Cyan

# NVIDIA GPU 확인
try {
    $gpuInfo = nvidia-smi --query-gpu=name --format=csv,noheader 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] nvidia-smi not found. CUDA Toolkit may not be installed." -ForegroundColor Red
        Write-Host "[INFO] Falling back to CPU miner..." -ForegroundColor Yellow
        
        if (!$SkipBuild) {
            Write-Host "`n[INFO] Building with CPU miner..." -ForegroundColor Green
            Set-Location node
            cargo build --release
        }
        
        Write-Host "`n[INFO] Running node with CPU miner..." -ForegroundColor Green
        Set-Location node
        cargo run --release
        exit
    }
    
    $gpu = $gpuInfo | Select-Object -First 1
    Write-Host "[INFO] Detected GPU: $gpu" -ForegroundColor Green
    
} catch {
    Write-Host "[WARN] Could not detect GPU. Building with default settings..." -ForegroundColor Yellow
    $gpu = "Unknown"
}

# GPU 모델에 따른 CUDA 아키텍처 매핑
$cudaArch = "sm_75"  # 기본값 (Turing 이상, CUDA 13.x 최소)
$gpuSupported = $true

if ($gpu -match "RTX (40|50)\d+") {
    # RTX 4000/5000 시리즈 (Ada Lovelace)
    $cudaArch = "sm_89"
    Write-Host "[INFO] Detected Ada Lovelace architecture (RTX 40/50 series)" -ForegroundColor Cyan
}
elseif ($gpu -match "RTX (30|A[456]\d+)") {
    # RTX 3000 시리즈 & A4000/A5000/A6000 (Ampere)
    $cudaArch = "sm_86"
    Write-Host "[INFO] Detected Ampere architecture (RTX 30 series)" -ForegroundColor Cyan
}
elseif ($gpu -match "RTX (20|TITAN RTX)|Quadro RTX") {
    # RTX 2000 시리즈 & Titan RTX (Turing)
    $cudaArch = "sm_75"
    Write-Host "[INFO] Detected Turing architecture (RTX 20 series)" -ForegroundColor Cyan
}
elseif ($gpu -match "GTX 16\d+") {
    # GTX 1600 시리즈 (Turing)
    $cudaArch = "sm_75"
    Write-Host "[INFO] Detected Turing architecture (GTX 16 series)" -ForegroundColor Cyan
}
elseif ($gpu -match "GTX (10\d+|TITAN X|TITAN Xp)") {
    # GTX 1000 시리즈 (Pascal) - CUDA 13.x에서 지원 안 됨
    Write-Host "[WARN] GTX 10 series (Pascal) is not supported by CUDA 13.x" -ForegroundColor Yellow
    Write-Host "[WARN] CUDA 13.x requires Turing (sm_75) or newer" -ForegroundColor Yellow
    Write-Host "[INFO] Please install CUDA 12.x for Pascal GPU support" -ForegroundColor Yellow
    Write-Host "[INFO] Download: https://developer.nvidia.com/cuda-12-6-0-download-archive" -ForegroundColor Cyan
    Write-Host "[INFO] Falling back to CPU miner..." -ForegroundColor Yellow
    $gpuSupported = $false
}
elseif ($gpu -match "GTX (9\d+|TITAN X)") {
    # GTX 900 시리즈 (Maxwell) - CUDA 13.x에서 지원 안 됨
    Write-Host "[WARN] GTX 900 series (Maxwell) is not supported by CUDA 13.x" -ForegroundColor Yellow
    Write-Host "[INFO] Please install CUDA 12.x for Maxwell GPU support" -ForegroundColor Yellow
    Write-Host "[INFO] Falling back to CPU miner..." -ForegroundColor Yellow
    $gpuSupported = $false
}
else {
    Write-Host "[INFO] Using default architecture: $cudaArch (Turing and newer)" -ForegroundColor Yellow
}

# CUDA Toolkit 확인
try {
    $nvccVersion = nvcc --version 2>&1 | Select-String -Pattern "release (\d+\.\d+)" | ForEach-Object { $_.Matches.Groups[1].Value }
    if ($nvccVersion) {
        Write-Host "[INFO] CUDA Toolkit version: $nvccVersion" -ForegroundColor Green
    }
} catch {
    Write-Host "[ERROR] nvcc not found. Please install CUDA Toolkit." -ForegroundColor Red
    Write-Host "Download from: https://developer.nvidia.com/cuda-downloads" -ForegroundColor Yellow
    exit 1
}

# GPU 호환성 체크 - CUDA로 빌드할 수 없으면 CPU로 폴백
if (-not $gpuSupported) {
    if (!$SkipBuild) {
        Write-Host "`n[INFO] Building with CPU miner..." -ForegroundColor Green
        Set-Location node
        cargo build --release
        Set-Location ..
    }
    
    Write-Host "`n[INFO] Starting node with CPU miner..." -ForegroundColor Green
    Write-Host "==========================================`n" -ForegroundColor Cyan
    
    Set-Location node
    cargo run --release
    exit 0
}

# 빌드
if (!$SkipBuild) {
    Write-Host "`n[INFO] Building with CUDA architecture: $cudaArch" -ForegroundColor Green
    
    # 환경 변수 설정
    $env:CUDA_ARCH = $cudaArch
    $env:MINER_BACKEND = "cuda"
    
    # core 패키지만 클린 (전체 빌드 캐시는 유지)
    Write-Host "[INFO] Cleaning previous CUDA build..." -ForegroundColor Yellow
    Set-Location node
    cargo clean -p Astram-core
    
    # 빌드
    Write-Host "[INFO] Building node with CUDA miner..." -ForegroundColor Green
    $buildResult = cargo build --release --features cuda-miner 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n[ERROR] Build failed!" -ForegroundColor Red
        $buildResult | Select-String -Pattern "error" | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        exit 1
    }
    
    # 빌드 경고 표시
    $warnings = $buildResult | Select-String -Pattern "warning.*CUDA|PTX"
    if ($warnings) {
        Write-Host "`n[BUILD INFO]" -ForegroundColor Cyan
        $warnings | ForEach-Object { Write-Host $_ }
    }
    
    Write-Host "`n[SUCCESS] Build completed!" -ForegroundColor Green
    Set-Location ..
} else {
    Write-Host "`n[INFO] Skipping build (using existing binary)" -ForegroundColor Yellow
}

# 실행
Write-Host "`n[INFO] Starting node with CUDA miner..." -ForegroundColor Green
Write-Host "[INFO] Press Ctrl+C to stop mining" -ForegroundColor Yellow
Write-Host "==========================================`n" -ForegroundColor Cyan

# MINER_BACKEND 환경 변수 설정
$env:MINER_BACKEND = "cuda"

# CUDA 배치 사이즈 설정 (선택사항)
if (-not $env:CUDA_BATCH_SIZE) {
    # GPU 메모리에 따라 기본 배치 사이즈 조정
    if ($gpu -match "RTX (40|30)") {
        $env:CUDA_BATCH_SIZE = "10000000"  # RTX 30/40 시리즈: 큰 배치
        Write-Host "[INFO] Using large batch size for high-end GPU: 10M hashes/batch" -ForegroundColor Cyan
    } elseif ($gpu -match "RTX 20|GTX 16") {
        $env:CUDA_BATCH_SIZE = "5000000"   # RTX 20/GTX 16 시리즈: 중간 배치
        Write-Host "[INFO] Using medium batch size: 5M hashes/batch" -ForegroundColor Cyan
    } else {
        $env:CUDA_BATCH_SIZE = "2000000"   # GTX 10 이하: 작은 배치
        Write-Host "[INFO] Using smaller batch size for older GPU: 2M hashes/batch" -ForegroundColor Cyan
    }
}

Set-Location node
cargo run --release --features cuda-miner
