#Requires -Version 5.1

# Test script to validate ExecutiveSummaryGenerator.ps1
Write-Host "Validating ExecutiveSummaryGenerator.ps1..." -ForegroundColor Cyan

try {
    # Load System.Web for HTML encoding
    Add-Type -AssemblyName System.Web

    # Dot-source the script
    . "$PSScriptRoot\ProcmonConverter-Production-Ready-20251105-214531\ExecutiveSummaryGenerator.ps1"

    Write-Host "✓ Script parsed successfully" -ForegroundColor Green

    # Test class instantiation
    $config = [ReportConfiguration]::new()
    Write-Host "✓ ReportConfiguration class loaded" -ForegroundColor Green

    $generator = [ExecutiveSummaryGenerator]::new()
    Write-Host "✓ ExecutiveSummaryGenerator class loaded" -ForegroundColor Green

    # Verify error handling infrastructure
    $errorDetail = [ErrorDetail]::new([ErrorSeverity]::Info, [ErrorCategory]::Processing, "Test message")
    Write-Host "✓ ErrorDetail class loaded" -ForegroundColor Green

    $retryPolicy = [RetryPolicy]::new()
    Write-Host "✓ RetryPolicy class loaded" -ForegroundColor Green

    Write-Host "`n=== VALIDATION SUCCESSFUL ===" -ForegroundColor Green
    Write-Host "All classes loaded and syntax is correct!" -ForegroundColor Green

    exit 0
}
catch {
    Write-Host "`n=== VALIDATION FAILED ===" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
    Write-Host "Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
    exit 1
}
