#Requires -Version 5.1

<#
.SYNOPSIS
    Test script to verify path with spaces fix

.DESCRIPTION
    Tests the Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1
    to ensure it properly handles paths containing spaces.
#>

param(
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
$ScriptRoot = $PSScriptRoot

Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           Testing Path with Spaces Fix                              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Test 1: Verify script exists
Write-Host "[Test 1] Verifying main script exists..." -ForegroundColor Yellow
$mainScript = Join-Path $ScriptRoot "Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1"
if (Test-Path $mainScript) {
    Write-Host "  ✓ Main script found: $mainScript" -ForegroundColor Green
} else {
    Write-Host "  ✗ Main script NOT found" -ForegroundColor Red
    exit 1
}

# Test 2: Verify Generate-Professional-Report.ps1 exists
Write-Host "`n[Test 2] Verifying Generate-Professional-Report.ps1 exists..." -ForegroundColor Yellow
$reportScript = Join-Path $ScriptRoot "Generate-Professional-Report.ps1"
if (Test-Path $reportScript) {
    Write-Host "  ✓ Report generator found: $reportScript" -ForegroundColor Green
} else {
    Write-Host "  ✗ Report generator NOT found" -ForegroundColor Red
    exit 1
}

# Test 3: Verify StreamingCSVProcessor.ps1 exists
Write-Host "`n[Test 3] Verifying StreamingCSVProcessor.ps1 exists..." -ForegroundColor Yellow
$processorScript = Join-Path $ScriptRoot "StreamingCSVProcessor.ps1"
if (Test-Path $processorScript) {
    Write-Host "  ✓ Streaming processor found: $processorScript" -ForegroundColor Green
} else {
    Write-Host "  ✗ Streaming processor NOT found" -ForegroundColor Red
    exit 1
}

# Test 4: Verify Data\SampleData exists
Write-Host "`n[Test 4] Verifying sample data directory..." -ForegroundColor Yellow
$sampleDataDir = Join-Path $ScriptRoot "Data\SampleData"
if (Test-Path $sampleDataDir -PathType Container) {
    Write-Host "  ✓ Sample data directory found: $sampleDataDir" -ForegroundColor Green

    $csvFiles = Get-ChildItem -Path $sampleDataDir -Filter "*.csv" -File
    if ($csvFiles.Count -gt 0) {
        Write-Host "  ✓ Found $($csvFiles.Count) CSV file(s)" -ForegroundColor Green
    } else {
        Write-Host "  ! No CSV files found in sample data" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ Sample data directory NOT found" -ForegroundColor Red
    exit 1
}

# Test 5: Test dot-sourcing with quoted path
Write-Host "`n[Test 5] Testing dot-source with quoted path..." -ForegroundColor Yellow
try {
    $testPath = $reportScript
    Write-Host "  Testing: . `"$testPath`"" -ForegroundColor Gray

    # This should work with quotes
    . "$testPath"

    Write-Host "  ✓ Dot-sourcing with quotes successful!" -ForegroundColor Green

    # Check if function is available
    if (Get-Command "New-ProfessionalReport" -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ New-ProfessionalReport function loaded" -ForegroundColor Green
    } else {
        Write-Host "  ! New-ProfessionalReport function not available" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ✗ Dot-sourcing failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Execute main script
Write-Host "`n[Test 6] Executing main script..." -ForegroundColor Yellow
Write-Host "  Command: & `"$mainScript`" -InputDirectory `"$sampleDataDir`"" -ForegroundColor Gray
Write-Host "`n" -NoNewline

try {
    & $mainScript -InputDirectory $sampleDataDir -ErrorAction Stop
    Write-Host "`n  ✓ Script execution completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "`n  ✗ Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
}

Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    TEST COMPLETE                                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
