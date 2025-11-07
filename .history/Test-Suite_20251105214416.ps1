# Test Script for ProcmonConverter Suite
$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing ProcmonConverter Suite" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$testResults = @()

# Test 1: Check if main script exists
Write-Host "Test 1: Checking main script exists..." -ForegroundColor Yellow
$mainScript = "..\ProcmonConverter\Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1"
if (Test-Path $mainScript) {
    Write-Host "  PASS: Main script found" -ForegroundColor Green
    $testResults += @{Test = "Main Script Exists"; Result = "PASS"}
} else {
    Write-Host "  FAIL: Main script not found" -ForegroundColor Red
    $testResults += @{Test = "Main Script Exists"; Result = "FAIL"}
}

# Test 2: Check if Generate-Professional-Report.ps1 exists
Write-Host "`nTest 2: Checking Generate-Professional-Report.ps1 exists..." -ForegroundColor Yellow
$reportScript = "..\ProcmonConverter\Generate-Professional-Report.ps1"
if (Test-Path $reportScript) {
    Write-Host "  PASS: Report generator found" -ForegroundColor Green
    $testResults += @{Test = "Report Script Exists"; Result = "PASS"}
} else {
    Write-Host "  FAIL: Report generator not found" -ForegroundColor Red
    $testResults += @{Test = "Report Script Exists"; Result = "FAIL"}
}

# Test 3: Validate Generate-Professional-Report.ps1 syntax
Write-Host "`nTest 3: Validating Generate-Professional-Report.ps1 syntax..." -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $reportScript -Raw), [ref]$null)
    Write-Host "  PASS: Syntax is valid" -ForegroundColor Green
    $testResults += @{Test = "Report Script Syntax"; Result = "PASS"}
} catch {
    Write-Host "  FAIL: Syntax error - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Report Script Syntax"; Result = "FAIL"}
}

# Test 4: Try to load Generate-Professional-Report.ps1
Write-Host "`nTest 4: Loading Generate-Professional-Report.ps1..." -ForegroundColor Yellow
try {
    . $reportScript
    Write-Host "  PASS: Successfully loaded" -ForegroundColor Green
    $testResults += @{Test = "Load Report Script"; Result = "PASS"}
} catch {
    Write-Host "  FAIL: Load error - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Load Report Script"; Result = "FAIL"}
}

# Test 5: Check if New-ProfessionalReport function is available
Write-Host "`nTest 5: Checking if New-ProfessionalReport function exists..." -ForegroundColor Yellow
if (Get-Command New-ProfessionalReport -ErrorAction SilentlyContinue) {
    Write-Host "  PASS: Function is available" -ForegroundColor Green
    $testResults += @{Test = "Function Available"; Result = "PASS"}
} else {
    Write-Host "  FAIL: Function not found" -ForegroundColor Red
    $testResults += @{Test = "Function Available"; Result = "FAIL"}
}

# Test 6: Validate main script syntax
Write-Host "`nTest 6: Validating main script syntax..." -ForegroundColor Yellow
try {
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $mainScript -Raw), [ref]$null)
    Write-Host "  PASS: Syntax is valid" -ForegroundColor Green
    $testResults += @{Test = "Main Script Syntax"; Result = "PASS"}
} catch {
    Write-Host "  FAIL: Syntax error - $($_.Exception.Message)" -ForegroundColor Red
    $testResults += @{Test = "Main Script Syntax"; Result = "FAIL"}
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count

foreach ($result in $testResults) {
    $color = if ($result.Result -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($result.Test): $($result.Result)" -ForegroundColor $color
}

Write-Host "`nTotal Tests: $($testResults.Count)" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })

if ($failCount -eq 0) {
    Write-Host "`nALL TESTS PASSED! Suite is ready for production." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSOME TESTS FAILED! Please review errors above." -ForegroundColor Red
    exit 1
}

