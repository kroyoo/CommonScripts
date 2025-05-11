# 设置日志文件路径
$logPath = "C:\Project\Program\Nginx\logs"

$daysToKeep = 15

# 获取当前日期
$currentDate = Get-Date

# 获取所有zip日志文件
$logZipFiles = Get-ChildItem -Path $logPath -Filter "*.zip"

foreach ($logFile in $logZipFiles) {
    # 获取文件的最后修改日期
    $lastWriteTime = $logFile.LastWriteTime

    # 计算文件的年龄
    $fileAge = $currentDate - $lastWriteTime
    Write-Host $fileAge

    # 如果文件的年龄超过指定天数，则删除
    if ($fileAge.Days -gt $daysToKeep) {
        Remove-Item $logFile.FullName -Force
    }
}


# 获取当前日期
$currentDate = Get-Date -Format "yyyy-MM-dd"

# 获取所有 .log 文件
$logFiles = Get-ChildItem -Path $logPath -Filter "*.log"

Stop-Process -Name nginx -Force
foreach ($logFile in $logFiles) {
    # 创建新的备份文件名
    $backupLogFileName = "$($logFile.BaseName)-$currentDate.log"
    $backupLogFilePath = Join-Path -Path $logPath -ChildPath $backupLogFileName

    # 重命名日志文件
    Rename-Item -Path $logFile.FullName -NewName $backupLogFileName -Force

    # 压缩重命名后的日志文件
    $zipFilePath = Join-Path -Path $logPath -ChildPath "$($logFile.BaseName)-$currentDate.zip"

    # 如果目标文件已存在，则删除
    if (Test-Path $zipFilePath) {
        Remove-Item -Path $zipFilePath -Force
    }
    Compress-Archive -Path $backupLogFilePath -DestinationPath $zipFilePath

    # 删除未压缩的日志文件
    Remove-Item -Path $backupLogFilePath -Force
}


# 重新打开 Nginx 日志
Start-Process -FilePath "C:\Project\Program\Nginx\nginx.exe"
