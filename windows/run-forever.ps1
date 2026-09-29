# Bot + saytni doimiy ishlatish: to'xtab qolsa 5 soniyadan keyin qayta ishga tushiradi.
# Loglar: logs\bot.log
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
New-Item -ItemType Directory -Force -Path "$root\logs" | Out-Null
$log = "$root\logs\bot.log"

while ($true) {
    # Log fayli juda kattalashib ketmasin (10 MB dan oshsa eskisini saqlab, yangisini boshlaymiz)
    if ((Test-Path $log) -and (Get-Item $log).Length -gt 10MB) {
        Move-Item -Force $log "$log.old"
    }
    Add-Content -Encoding utf8 $log "===== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ishga tushirilmoqda ====="
    # cmd orqali — node'ning UTF-8 chiqishi o'zgarmasdan faylga yoziladi
    cmd /c "node index.js >> `"$log`" 2>&1"
    Add-Content -Encoding utf8 $log "===== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') to'xtadi (kod $LASTEXITCODE), 5 soniyadan keyin qayta ====="
    Start-Sleep -Seconds 5
}
