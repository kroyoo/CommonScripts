# --- 配置区域 ---
$logPath = "C:\Project\Program\Nginx\logs"              # Nginx 日志文件所在目录
$nginxExePath = "C:\Project\Program\Nginx\nginx.exe"     # Nginx.exe 的完整路径

# Nginx 前缀路径 (prefix path)。这是 Nginx 安装的根目录，其中包含 conf, logs, html 等子目录。
# 对于 `nginx -s reopen` 命令，如果 Nginx 无法自动确定其配置文件的位置，
# (例如，当从其他目录调用 nginx.exe 时，或者 Nginx 服务本身没有正确设置工作目录时)
# 则必须通过 `-p` 参数指定此前缀路径。
# 如果你的 Nginx 配置简单，且 nginx.exe 能够自行找到配置文件，此项可以留空 ($null 或 "")。
# 示例: $nginxPrefixPath = "C:\nginx-1.24.0"
$nginxPrefixPath = "C:\Project\Program\Nginx"        # 请根据你的实际 Nginx 安装路径修改

$daysToKeep = 15                                         # 日志压缩包保留天数 (单位: 天)
$dateFormat = "yyyy-MM-dd_HH-mm-ss"                      # 日志轮转时文件名中附加的日期格式
                                                         # 如果希望每天只轮转一次且格式为 YYYY-MM-DD，可以设置为 "yyyy-MM-dd"

# --- 脚本开始 ---
Write-Host "Nginx 日志零停机轮转脚本 (使用 -s reopen) 开始于 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "重要提示: 请确保以管理员权限或 Nginx 运行用户权限运行此脚本, 以便成功发送 'reopen' 信号。"
Write-Host "如果 'reopen' 信号失败，请检查 Nginx 错误日志以及 '$nginxPrefixPath' 配置是否正确。"
Write-Host "--------------------------------------------------"

# --- 1. 清理旧的日志压缩包 ---
# 此部分与之前的脚本（停止Nginx版本）基本相同
Write-Host "阶段 1: 清理旧的日志压缩包 (保留 $daysToKeep 天)..."
try {
    if (-not (Test-Path -Path $logPath -PathType Container)) {
        Write-Warning "日志目录 '$logPath' 不存在。跳过清理操作。"
    } else {
        $currentDateForCleanup = Get-Date
        $logZipFiles = Get-ChildItem -Path $logPath -Filter "*.zip" -File -ErrorAction SilentlyContinue

        if ($logZipFiles.Count -eq 0) {
            Write-Host "在 '$logPath' 中未找到需要清理的 .zip 压缩包。"
        } else {
            Write-Host "发现 $($logZipFiles.Count) 个 .zip 压缩包，开始检查文件龄..."
            foreach ($logFile in $logZipFiles) {
                $lastWriteTime = $logFile.LastWriteTime
                $fileAge = $currentDateForCleanup - $lastWriteTime
                Write-Verbose "正在检查压缩包: $($logFile.Name), 文件龄: $($fileAge.Days) 天, 最后修改时间: $lastWriteTime" # 使用 -Verbose 参数运行时显示
                if ($fileAge.Days -gt $daysToKeep) {
                    Write-Host "准备删除旧压缩包: $($logFile.FullName) (文件龄: $($fileAge.Days) 天, 已超过 $daysToKeep 天)"
                    Remove-Item -Path $logFile.FullName -Force -ErrorAction Stop # 若删除失败则中断此文件处理
                    Write-Host "已删除: $($logFile.FullName)"
                } else {
                    Write-Verbose "跳过压缩包: $($logFile.Name) (文件龄: $($fileAge.Days) 天, 未超过 $daysToKeep 天)"
                }
            }
        }
        Write-Host "旧日志压缩包清理完成。"
    }
} catch {
    Write-Error "清理旧日志压缩包时发生错误: $($_.Exception.Message)"
}
Write-Host "--------------------------------------------------"

# --- 2. 使用 'nginx -s reopen' 轮转当前的日志文件 ---
Write-Host "阶段 2: 使用 'nginx -s reopen' 轮转当前的 .log 日志文件..."
try {
    # 检查核心路径配置
    if (-not (Test-Path -Path $logPath -PathType Container)) {
        Write-Error "错误: 日志目录 '$logPath' 不存在。无法进行日志轮转。"
        throw "日志目录 '$logPath' 未找到。" # 抛出异常，终止此阶段
    }
    if (-not (Test-Path -Path $nginxExePath -PathType Leaf)) {
        Write-Error "错误: Nginx 可执行文件 '$nginxExePath' 未找到。无法进行日志轮转。"
        throw "Nginx 可执行文件 '$nginxExePath' 未找到。"
    }
    # 检查 Nginx 前缀路径是否有效 (如果已配置)
    if ($nginxPrefixPath -and (-not (Test-Path -Path $nginxPrefixPath -PathType Container))) {
        Write-Warning "警告: 配置的 Nginx 前缀路径 '$nginxPrefixPath' 无效或不存在。"
        Write-Warning " `-s reopen` 命令可能不带 `-p` 参数执行，或执行失败。请确认此配置是否为环境所必需。"
        # 根据实际情况，这里也可以选择 throw 异常，如果 `-p` 参数对你的环境是必需的
    }

    $currentRotationTimestamp = Get-Date -Format $dateFormat
    $activeLogFiles = Get-ChildItem -Path $logPath -Filter "*.log" -File -ErrorAction SilentlyContinue

    if (-not $activeLogFiles) {
        Write-Host "在 '$logPath' 中未找到活动的 .log 文件进行轮转。"
    } else {
        $renamedLogFilePaths = [System.Collections.ArrayList]::new() # 用于存储成功重命名的文件路径

        # 步骤 A: 重命名所有活动的 .log 文件
        # Nginx 在收到 reopen 信号前，我们先将当前的日志文件重命名。
        # Nginx 之后会创建新的、与原文件名相同的空日志文件。
        Write-Host "`n步骤 A: 重命名活动的 .log 文件..."
        foreach ($logFile in $activeLogFiles) {
            $baseName = $logFile.BaseName
            $extension = $logFile.Extension # 通常是 .log
            $rotatedLogFileName = "$baseName-$currentRotationTimestamp$extension" # 例如: access-2025-05-25_19-45-00.log
            $rotatedLogFilePath = Join-Path -Path $logPath -ChildPath $rotatedLogFileName
            
            try {
                Write-Host "  准备重命名 '$($logFile.FullName)' 为 '$rotatedLogFilePath'"
                Rename-Item -Path $logFile.FullName -NewName $rotatedLogFileName -Force -ErrorAction Stop
                [void]$renamedLogFilePaths.Add($rotatedLogFilePath) # 将成功重命名的文件路径添加到列表
                Write-Host "  已成功重命名为 '$rotatedLogFilePath'"
            } catch {
                Write-Error "  重命名文件 '$($logFile.FullName)' 失败: $($_.Exception.Message)"
                Write-Warning "  此文件将不会被轮转。Nginx 可能会在 'reopen' 后继续写入此文件 (如果句柄未释放) 或创建新文件。"
            }
        }

        if ($renamedLogFilePaths.Count -eq 0) {
            Write-Host "没有文件被成功重命名，跳过 Nginx 'reopen' 信号和后续压缩步骤。"
        } else {
            # 步骤 B: 发送 'reopen' 信号给 Nginx
            Write-Host "`n步骤 B: 发送 'reopen' 信号给 Nginx..."
            $nginxSignalArgs = @("-s", "reopen") # 基本参数
            # 如果配置了 Nginx 前缀路径且该路径存在，则添加 -p 参数
            if ($nginxPrefixPath -and (Test-Path -Path $nginxPrefixPath -PathType Container)) {
                # 使用反引号 `"` 来包围可能含有空格的路径
                $nginxSignalArgs += @("-p", "`"$nginxPrefixPath`"")
                Write-Host "  将使用 Nginx 前缀路径 (prefix path): $nginxPrefixPath"
            } else {
                Write-Host "  Nginx 前缀路径未配置、无效或不需要。将不使用 '-p' 参数。"
                Write-Host "  如果 'reopen' 失败，请考虑配置正确的 '$nginxPrefixPath'。"
            }
            
            $reopenSignalSuccess = $false
            try {
                Write-Host "  执行命令: `"$nginxExePath`" $($nginxSignalArgs -join ' ')"
                # -Wait: 等待命令完成; -PassThru: 返回进程对象; -NoNewWindow: 不创建新命令行窗口
                $process = Start-Process -FilePath $nginxExePath -ArgumentList $nginxSignalArgs -Wait -PassThru -NoNewWindow -ErrorAction Stop
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "  Nginx 'reopen' 信号发送成功 (退出码: 0)。Nginx 应已重新打开新的日志文件。"
                    $reopenSignalSuccess = $true
                    Start-Sleep -Seconds 2 # 给 Nginx 一点时间来实际完成文件句柄的切换
                } else {
                    # 非0退出码表示 `nginx -s reopen` 可能遇到问题
                    Write-Warning "  Nginx 'reopen' 信号命令执行完毕，但退出码为 $($process.ExitCode) (非0)。"
                    Write-Warning "  这可能表示 'reopen' 操作未完全成功。请检查 Nginx 的错误日志 (通常在 logs/error.log 中)。"
                    Write-Warning "  日志文件已被重命名，但 Nginx 可能未正确创建新的日志文件。"
                    # 即使信号可能未完全成功，也尝试继续压缩已重命名的文件，因为它们理论上已不再是 Nginx 的主要写入目标。
                }
            } catch {
                Write-Error "  发送 'reopen' 信号给 Nginx 时发生严重错误: $($_.Exception.Message)"
                Write-Warning "  日志文件已被重命名，但 Nginx 可能未能重新打开新的日志文件。"
                Write-Warning "  强烈建议手动检查 Nginx 状态和日志文件！"
            }

            # 步骤 C: 压缩已重命名的日志文件，然后删除原始的已重命名文件
            Write-Host "`n步骤 C: 压缩已重命名的日志文件 (之前步骤中重命名的 *.log 文件)..."
            foreach ($logToProcessPath in $renamedLogFilePaths) {
                if (-not (Test-Path $logToProcessPath -PathType Leaf)) { # 确保文件存在且是文件
                    Write-Warning "  文件 '$logToProcessPath' 在准备压缩时未找到或不是文件。跳过此文件。"
                    continue
                }

                $fileItem = Get-Item $logToProcessPath
                # 从形如 "access-2025-05-25_19-45-00.log" 的文件名中提取 "access-2025-05-25_19-45-00" 作为压缩包名
                $zipFileBaseName = $fileItem.BaseName 
                $zipFilePath = Join-Path -Path $logPath -ChildPath "$zipFileBaseName.zip"

                try {
                    Write-Host "  准备压缩 '$logToProcessPath' 到 '$zipFilePath'"
                    if (Test-Path $zipFilePath) {
                        Write-Warning "    警告: 目标压缩包 '$zipFilePath' 已存在。将先删除旧的压缩包。"
                        Remove-Item -Path $zipFilePath -Force -ErrorAction Stop
                    }
                    Compress-Archive -Path $logToProcessPath -DestinationPath $zipFilePath -CompressionLevel Optimal -ErrorAction Stop
                    Write-Host "    成功压缩到 '$zipFilePath'"

                    Write-Host "    准备删除已压缩的源文件 '$logToProcessPath'"
                    Remove-Item -Path $logToProcessPath -Force -ErrorAction Stop
                    Write-Host "    已成功删除 '$logToProcessPath'"
                } catch {
                    Write-Error "  处理已重命名的文件 '$logToProcessPath' (在压缩或删除阶段) 时发生错误: $($_.Exception.Message)"
                    Write-Warning "  文件 '$logToProcessPath' 或其压缩版本 '$zipFilePath' 可能仍残留在磁盘上。请手动检查。"
                }
            }
        } # end if ($renamedLogFilePaths.Count -gt 0)
    } # end if (-not $activeLogFiles)
} catch {
    Write-Error "在日志轮转主阶段发生严重错误: $($_.Exception.Message)"
    Write-Warning "日志轮转可能未完成或部分完成。请手动检查 Nginx 状态和日志文件。"
}

Write-Host "--------------------------------------------------"
Write-Host "Nginx 日志零停机轮转脚本完成于 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
