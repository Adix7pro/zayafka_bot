# Kompyuter yoqilib, Windows'ga kirilganda bot avtomatik (yashirin oynada) ishga tushsin.
# Ishlatish:  powershell -ExecutionPolicy Bypass -File windows\install-autostart.ps1
$taskName = 'zayafka_bot'
$script = Join-Path $PSScriptRoot 'run-forever.ps1'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "✅ '$taskName' o'rnatildi va ishga tushirildi. Loglar: logs\bot.log"
