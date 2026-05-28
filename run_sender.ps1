# ============================================================
# CHAY TREN MAY SENDER (Nguyen Hoang)
# Dieu kien: Receiver da chay run_receiver.ps1 truoc
# Vi du    : .\run_sender.ps1 -ReceiverIP 192.168.1.10
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$ReceiverIP,

    [int]$DataPort = 6000,
    [int]$KeyPort  = 8080,
    [string]$Message = "Xin chao FIT4012! Day la ban tin Lab 8: DES-CBC + SHA-256 + RSA-OAEP. Dang Quang Tien & Nguyen Hoang."
)

Set-Location $PSScriptRoot

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Khong tim thay python. Vui long cai Python 3.10+."
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SENDER - Nguyen Hoang" -ForegroundColor Cyan
Write-Host "  Receiver IP : $ReceiverIP" -ForegroundColor Yellow
Write-Host "  Data port   : $DataPort" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# --- Tao thu muc keys neu chua co ---
New-Item -ItemType Directory -Force -Path "keys" | Out-Null

# --- Tai public key tu Receiver qua HTTP ---
$keyUrl  = "http://${ReceiverIP}:${KeyPort}/keys/receiver_public.pem"
$keyFile = "keys/receiver_public.pem"

Write-Host "[*] Tai RSA public key cua Receiver tu $keyUrl ..." -ForegroundColor Gray

try {
    Invoke-WebRequest -Uri $keyUrl -OutFile $keyFile -UseBasicParsing -ErrorAction Stop
    Write-Host "[+] Da tai public key thanh cong ($keyFile)." -ForegroundColor Green
} catch {
    Write-Error "Khong tai duoc public key tu $keyUrl"
    Write-Host "    Kiem tra: Receiver da chay run_receiver.ps1 chua? IP co dung khong?" -ForegroundColor Red
    exit 1
}

# --- Hien thi noi dung public key de minh chung ---
Write-Host ""
Write-Host "[*] Noi dung RSA Public Key nhan duoc:" -ForegroundColor Gray
Get-Content $keyFile | Select-Object -First 3
Write-Host "    ..."
Write-Host ""

# --- Gui ban tin ---
Write-Host "[*] Bat dau gui ban tin ma hoa..." -ForegroundColor Cyan

$env:SERVER_IP            = $ReceiverIP
$env:DATA_PORT            = "$DataPort"
$env:RECEIVER_PUBLIC_KEY  = $keyFile
$env:MESSAGE              = $Message
$env:SENDER_LOG_FILE      = "logs/sender_success.log"
Remove-Item Env:\INPUT_FILE -ErrorAction SilentlyContinue

python sender.py

Write-Host ""
Write-Host "[+] Xong! Kiem tra logs/sender_success.log de xem chi tiet." -ForegroundColor Green
