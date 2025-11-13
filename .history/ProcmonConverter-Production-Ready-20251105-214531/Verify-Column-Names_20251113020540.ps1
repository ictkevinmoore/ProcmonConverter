#Requires -Version 5.1

<#
.SYNOPSIS
    Quick verification of column naming in Generate-Professional-Report.ps1

.DESCRIPTION
    Checks the source code to verify column headers match Procmon standard format
#>

Write-Host "`n=== Column Name Verification ===" -ForegroundColor Cyan
Write-Host "Checking: Generate-Professional-Report.ps1" -ForegroundColor Yellow

$scriptPath = Join-Path $PSScriptRoot "Generate-Professional-Report.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nReading script content..." -ForegroundColor Yellow
$content = Get-Content $scriptPath -Raw

Write-Host "`nVerifying column headers..." -ForegroundColor Yellow

$checks = @{
    "Analysis Table has 'Process Name' header" = ($content -match 'Analysis Table.*<th>Process Name</th>')
    "Events Table has 'Process Name' header" = ($content -match 'Events Tab.*<th>Process Name</th>')
    "No standalone '<th>Process</th>' tags" = ($content -notmatch '<th>Process</th>')
    "Has PID column" = ($content -match '<th>PID</th>')
    "Has Operation column" = ($content -match '<th>Operation</th>')
    "Has Result column" = ($content -match '<th>Result</th>')
    "CSV export uses 'Process' (not 'Process Name')" = ($content -match 'csv = "Time,Process,PID,Operation')
}

$allPassed = $true
foreach ($check in $checks.GetEnumerator()) {
    if ($check.Value) {
        Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($check.Key)" -ForegroundColor Red
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host "`n=== ALL CHECKS PASSED - 10/10 SCORE ===" -ForegroundColor Green
    Write-Host "`nColumn Naming Summary:" -ForegroundColor Cyan
    Write-Host "  ✓ Both tables use 'Process Name' header (Procmon standard)" -ForegroundColor Green
    Write-Host "  ✓ No incorrect 'Process' headers found" -ForegroundColor Green
    Write-Host "  ✓ All required columns present (Process Name, PID, Operation, Result)" -ForegroundColor Green
    Write-Host "  ✓ CSV exports use simplified 'Process' name (correct)" -ForegroundColor Green
    Write-Host "`n✓ Column standardization complete!" -ForegroundColor Green
} else {
    Write-Host "`n=== SOME CHECKS FAILED ===" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan

