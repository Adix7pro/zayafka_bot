# Cloudflare Tunnel: newworld.uz -> http://localhost:3000
# Oldin bir marta: cloudflared tunnel login  (brauzerda newworld.uz ga ruxsat berish)
# Ishlatish:  powershell -ExecutionPolicy Bypass -File windows\setup-tunnel.ps1
$ErrorActionPreference = 'Stop'
$cf = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
if (-not $cf) { $cf = 'C:\Program Files (x86)\cloudflared\cloudflared.exe' }
$name = 'newworld'
$dir = "$env:USERPROFILE\.cloudflared"

if (-not (Test-Path "$dir\cert.pem")) { throw "Avval 'cloudflared tunnel login' ni bajaring" }

# 1. Tunnel (bor bo'lsa qayta yaratmaymiz)
$list = & $cf tunnel list --output json 2>$null | ConvertFrom-Json
$tunnel = $list | Where-Object { $_.name -eq $name } | Select-Object -First 1
if (-not $tunnel) {
    & $cf tunnel create $name
    $tunnel = & $cf tunnel list --output json 2>$null | ConvertFrom-Json | Where-Object { $_.name -eq $name } | Select-Object -First 1
}
$id = $tunnel.id
Write-Host "Tunnel: $name ($id)"

# 2. DNS: newworld.uz va www -> tunnel
& $cf tunnel route dns --overwrite-dns $name newworld.uz
& $cf tunnel route dns --overwrite-dns $name www.newworld.uz

# 3. Sozlama fayli
@"
tunnel: $id
credentials-file: $dir\$id.json
ingress:
  - hostname: newworld.uz
    service: http://localhost:3000
  - hostname: www.newworld.uz
    service: http://localhost:3000
  - service: http_status:404
"@ | Set-Content -Encoding ascii "$dir\config.yml"

# 4. Windows'ga kirganda avtomatik ishga tushsin (to'xtasa qayta yonadi)
$action = New-ScheduledTaskAction -Execute $cf -Argument "tunnel --config `"$dir\config.yml`" run"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -TaskName 'zayafka_tunnel' -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName 'zayafka_tunnel'
Write-Host "✅ Tunnel ishga tushdi: https://newworld.uz"
