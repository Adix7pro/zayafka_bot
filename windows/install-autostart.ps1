# Kompyuter yoqilib, Windows'ga kirilganda bot avtomatik (yashirin oynada) ishga tushsin.
# Ishlatish:  powershell -ExecutionPolicy Bypass -File windows\install-autostart.ps1
$taskName = 'zayafka_bot'
$script = Join-Path $PSScriptRoot 'run-forever.ps1'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
# Windows'ga kirganda + har 5 daqiqada tekshiruv: bot ishlayotgan bo'lsa hech narsa qilinmaydi
# (IgnoreNew), qandaydir sabab bilan o'chib qolgan bo'lsa — qayta yoqiladi
$triggers = @(
    (New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME),
    (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5))
)
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew `
    -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Host "✅ '$taskName' o'rnatildi va ishga tushirildi. Loglar: logs\bot.log"
