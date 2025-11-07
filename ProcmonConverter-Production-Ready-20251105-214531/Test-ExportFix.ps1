#Requires -Version 5.1

<#
.SYNOPSIS
    Test script to verify Export-ModuleMember fixes

.DESCRIPTION
    Tests that all analytics engine files load without Export-ModuleMember errors
#>

$ErrorActionPreference = 'Stop'
$testsPassed = 0
$testsFailed = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TESTING EXPORT-MODULEMEMBER FIXES" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: AdvancedAnalyticsEngine.ps1
Write-Host "[TEST 1/3] Loading AdvancedAnalyticsEngine.ps1..." -ForegroundColor Yellow
try {
    . "$PSScriptRoot\AdvancedAnalyticsEngine.ps1"
    Write-Host "  ✓ PASS: AdvancedAnalyticsEngine loaded successfully" -ForegroundColor Green
    $testsPassed++
}
catch {
    Write-Host "  ✗ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 2: PatternRecognitionEngine.ps1
Write-Host "[TEST 2/3] Loading PatternRecognitionEngine.ps1..." -ForegroundColor Yellow
try {
    . "$PSScriptRoot\PatternRecognitionEngine.ps1"
    Write-Host "  ✓ PASS: PatternRecognitionEngine loaded successfully" -ForegroundColor Green
    $testsPassed++
}
catch {
    Write-Host "  ✗ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 3: ExecutiveSummaryGenerator.ps1
Write-Host "[TEST 3/3] Loading ExecutiveSummaryGenerator.ps1..." -ForegroundColor Yellow
try {
    . "$PSScriptRoot\ExecutiveSummaryGenerator.ps1"
    Write-Host "  ✓ PASS: ExecutiveSummaryGenerator loaded successfully" -ForegroundColor Green
    $testsPassed++
}
catch {
    Write-Host "  ✗ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Test 4: Verify classes are available
Write-Host "`n[TEST 4/4] Verifying PowerShell classes are available..." -ForegroundColor Yellow
try {
    $analyticsEngine = [AdvancedAnalyticsEngine]::new()
    $patternEngine = [PatternRecognitionEngine]::new()
    $summaryGenerator = [ExecutiveSummaryGenerator]::new()

    if ($analyticsEngine -and $patternEngine -and $summaryGenerator) {
        Write-Host "  ✓ PASS: All classes instantiated successfully" -ForegroundColor Green
        $testsPassed++
    } else {
        throw "One or more classes failed to instantiate"
    }
}
catch {
    Write-Host "  ✗ FAIL: $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests Passed: " -NoNewline -ForegroundColor White
Write-Host "$testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: " -NoNewline -ForegroundColor White
if ($testsFailed -eq 0) {
    Write-Host "$testsFailed" -ForegroundColor Green
} else {
    Write-Host "$testsFailed" -ForegroundColor Red
}
Write-Host "========================================`n" -ForegroundColor Cyan

if ($testsFailed -eq 0) {
    Write-Host "✓✓✓ ALL TESTS PASSED - EXPORT-MODULEMEMBER ERROR FIXED ✓✓✓`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗✗✗ SOME TESTS FAILED - REVIEW ERRORS ABOVE ✗✗✗`n" -ForegroundColor Red
    exit 1
}

