# ============================================================
# CHAY TREN MAY RECEIVER (Dang Quang Tien)
# Buoc 1: chay script nay truoc
# Buoc 2: bao cho Sender biet IP va port key-server
# ============================================================

param(
    [int]$DataPort   = 6000,
    [int]$KeyPort    = 8080,
    [string]$Message = ""
)

Set-Location $PSScriptRoot

# --- Kiem tra Python ---
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Khong tim thay python. Vui long cai Python 3.10+."
    exit 1
}

# --- Lay IP LAN cua may nay ---
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -notmatch "^127\." -and $_.PrefixOrigin -ne "WellKnown" } |
       Select-Object -First 1).IPAddress

if (-not $ip) { $ip = "0.0.0.0" }

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  RECEIVER - Dang Quang Tien" -ForegroundColor Cyan
Write-Host "  IP may nay : $ip" -ForegroundColor Yellow
Write-Host "  Data port  : $DataPort" -ForegroundColor Yellow
Write-Host "  Key port   : $KeyPort  (Sender tai public key tai day)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Sinh cap khoa RSA neu chua co ---
if (-not (Test-Path "keys\receiver_private.pem")) {
    Write-Host "[*] Sinh cap khoa RSA..." -ForegroundColor Gray
    python keygen.py
} else {
    Write-Host "[*] Da co RSA key, bo qua keygen." -ForegroundColor Gray
}

# --- Phuc vu public key qua HTTP de Sender tai xuong ---
Write-Host "[*] Bat dau HTTP server port $KeyPort de chia se public key..."
Write-Host "    Sender chay lenh: python run_sender.ps1 -ReceiverIP $ip" -ForegroundColor Green
Write-Host ""

$keyJob = Start-Job -ScriptBlock {
    param($port)
    Set-Location $using:PSScriptRoot
    python -m http.server $port --directory . 2>$null
} -ArgumentList $KeyPort

# --- Cho Sender ket noi roi bat dau lang nghe ---
Write-Host "[*] Receiver dang lang nghe tai 0.0.0.0:$DataPort ..." -ForegroundColor Cyan

$env:RECEIVER_HOST        = "0.0.0.0"
$env:DATA_PORT            = "$DataPort"
$env:RECEIVER_PRIVATE_KEY = "keys/receiver_private.pem"
$env:RECEIVER_LOG_FILE    = "logs/receiver_success.log"
$env:OUTPUT_FILE          = "sample_output.txt"

try {
    python receiver.py
} finally {
    Stop-Job $keyJob -ErrorAction SilentlyContinue
    Remove-Job $keyJob -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "[+] Da tat HTTP key server." -ForegroundColor Gray
}
