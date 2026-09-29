# Botni to'xtatish (avtomatik ishga tushish saqlanib qoladi)
# Butunlay o'chirish:  Unregister-ScheduledTask -TaskName zayafka_bot -Confirm:$false
Stop-ScheduledTask -TaskName 'zayafka_bot' -ErrorAction SilentlyContinue

# run-forever.ps1 jarayonlari va ular ishga tushirgan node'lar
$wrappers = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object { $_.CommandLine -like '*run-forever.ps1*' })
$wrapperIds = $wrappers | ForEach-Object { $_.ProcessId }
$nodes = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
    Where-Object { $wrapperIds -contains $_.ParentProcessId })

($wrappers + $nodes) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host "Bot to'xtatildi"
