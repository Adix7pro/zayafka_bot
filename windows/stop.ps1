# Botni to'xtatish (avtomatik ishga tushish saqlanib qoladi)
# Butunlay o'chirish:  Unregister-ScheduledTask -TaskName zayafka_bot -Confirm:$false
Stop-ScheduledTask -TaskName 'zayafka_bot' -ErrorAction SilentlyContinue

$root = Split-Path -Parent $PSScriptRoot
$all = @(Get-CimInstance Win32_Process)

# run-forever.ps1 -> cmd.exe (node index.js >> logs\bot.log) -> node.exe
$wrappers = @($all | Where-Object { $_.Name -eq 'powershell.exe' -and $_.CommandLine -like '*run-forever.ps1*' })
$cmds = @($all | Where-Object { $_.Name -eq 'cmd.exe' -and $_.CommandLine -like '*node index.js*' -and $_.CommandLine -like "*$root*" })
$cmdIds = $cmds | ForEach-Object { $_.ProcessId }
$nodes = @($all | Where-Object { $_.Name -eq 'node.exe' -and $cmdIds -contains $_.ParentProcessId })

# Avval o'rovchini (qayta ishga tushirmasligi uchun), keyin node'ni to'xtatamiz
($wrappers + $cmds + $nodes) | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host "Bot to'xtatildi ($($nodes.Count) ta node jarayoni)"
