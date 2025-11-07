$sourcePath = "ProcmonSuite-Backup-20251101-113313\Generate-Professional-Report.ps1"
$destPath = "..\ProcmonConverter\Generate-Professional-Report.ps1"

Write-Host "`n=== Copying Generate-Professional-Report.ps1 ===" -ForegroundColor Cyan

# Verify source exists
if (!(Test-Path $sourcePath)) {
    Write-Host "ERROR: Source file not found: $sourcePath" -ForegroundColor Red
    exit 1
}

# Copy the file
try {
    Copy-Item -Path $sourcePath -Destination $destPath -Force
    Write-Host "File copied successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR during copy: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify the copy
$sourceSize = (Get-Item $sourcePath).Length
$destSize = (Get-Item $destPath).Length

Write-Host "`nSource size: $sourceSize bytes" -ForegroundColor White
Write-Host "Destination size: $destSize bytes" -ForegroundColor White

if ($sourceSize -eq $destSize) {
    Write-Host "`nSUCCESS: File copied correctly!" -ForegroundColor Green
} else {
    Write-Host "`nERROR: File sizes don't match!" -ForegroundColor Red
    exit 1
}

