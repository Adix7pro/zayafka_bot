# GitHub'dan yangi kodni olib, botni qayta ishga tushirish
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
git pull --ff-only
if (-not $?) { Write-Host "❌ git pull xato berdi"; exit 1 }
npm ci --omit=dev
& "$PSScriptRoot\stop.ps1"
Start-ScheduledTask -TaskName 'zayafka_bot'
Write-Host "✅ Yangilandi va qayta ishga tushdi"
