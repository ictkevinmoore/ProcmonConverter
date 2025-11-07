$sourceFile = "ProcmonSuite-Backup-20251101-113313\Generate-Professional-Report.ps1"
$targetFile = "..\ProcmonConverter\Generate-Professional-Report.ps1"

Write-Host "`n=== File Integrity Check ===" -ForegroundColor Cyan

$sourceSize = (Get-Item $sourceFile).Length
$targetSize = (Get-Item $targetFile).Length

Write-Host "Source file size: $sourceSize bytes" -ForegroundColor White
Write-Host "Target file size: $targetSize bytes" -ForegroundColor White

if ($sourceSize -eq $targetSize) {
    Write-Host "`nSUCCESS: Files match in size - copy was successful!" -ForegroundColor Green
} else {
    Write-Host "`nWARNING: File sizes differ!" -ForegroundColor Yellow
}

# Syntax check
Write-Host "`n=== Syntax Validation ===" -ForegroundColor Cyan
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $targetFile -Raw), [ref]$null)
    Write-Host "SUCCESS: Target file syntax is valid" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Syntax error detected: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== All Checks Passed ===" -ForegroundColor Green

