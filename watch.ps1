# Flutter Watch Script (like nodemon)
# This script watches for file changes and automatically restarts Flutter

$projectPath = $PSScriptRoot
$flutterProcess = $null

function Start-Flutter {
    Write-Host "Starting Flutter..." -ForegroundColor Green
    $global:flutterProcess = Start-Process -FilePath "flutter" -ArgumentList "run" -WorkingDirectory $projectPath -PassThru -NoNewWindow
}

function Stop-Flutter {
    if ($global:flutterProcess -and !$global:flutterProcess.HasExited) {
        Write-Host "Stopping Flutter..." -ForegroundColor Yellow
        Stop-Process -Id $global:flutterProcess.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

function Restart-Flutter {
    Stop-Flutter
    Start-Sleep -Seconds 1
    Start-Flutter
}

# Start Flutter initially
Start-Flutter

# Watch for file changes
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "$projectPath\lib"
$watcher.Filter = "*.dart"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $details = $event.SourceEventArgs
    $changeType = $details.ChangeType
    $name = $details.Name
    $path = $details.FullPath
    
    Write-Host "`n[$changeType] $name" -ForegroundColor Cyan
    Write-Host "Restarting Flutter..." -ForegroundColor Yellow
    Restart-Flutter
}

Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action | Out-Null
Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action | Out-Null

Write-Host "`nFlutter watch mode is running. Press Ctrl+C to stop." -ForegroundColor Green
Write-Host "Watching for changes in: $($watcher.Path)" -ForegroundColor Gray

try {
    # Keep script running
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "`nStopping watch mode..." -ForegroundColor Yellow
    Stop-Flutter
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
}

