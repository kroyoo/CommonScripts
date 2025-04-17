# process name
$processes = Get-WmiObject Win32_Process | Where-Object { $_.Name -eq "python.exe" } | Select-Object ProcessId, CommandLine

foreach ($process in $processes) {
    if ($process.CommandLine -like "*keywaord*") {
        Write-Host "Stop Process ID: $($process.ProcessId) - CommandLine: $($process.CommandLine)"
        Stop-Process -Id $process.ProcessId -Force
        Start-Sleep -Seconds 3
    }
}
