# Create Production Backup
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupName = "ProcmonConverter-Production-10-10-$timestamp"
$backupPath = Join-Path 'C:\Users\ictke\OneDrive\Desktop' $backupName

Write-Host "Creating production backup..." -ForegroundColor Cyan
Copy-Item -Path 'C:\Users\ictke\OneDrive\Desktop\ProcmonConverter' -Destination $backupPath -Recurse -Force

if (Test-Path $backupPath) {
    Write-Host "SUCCESS: Production backup created at:" -ForegroundColor Green
    Write-Host $backupPath -ForegroundColor Yellow
} else {
    Write-Host "ERROR: Backup creation failed" -ForegroundColor Red
}

