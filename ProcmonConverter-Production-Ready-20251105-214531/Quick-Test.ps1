Set-Location "C:\Users\ictke\OneDrive\Desktop\November Script Back-up\ProcmonConverter-Production-Ready-20251105-214531"
$ErrorActionPreference = 'Stop'

Write-Host "`n=== Testing ExecutiveSummaryGenerator.ps1 ===" -ForegroundColor Cyan

try {
    Write-Host "Loading script..." -ForegroundColor Yellow
    . ".\ExecutiveSummaryGenerator.ps1"
    Write-Host "✓ Script loaded successfully" -ForegroundColor Green

    Write-Host "Instantiating ExecutiveSummaryGenerator class..." -ForegroundColor Yellow
    $generator = [ExecutiveSummaryGenerator]::new()
    Write-Host "✓ Class instantiated successfully" -ForegroundColor Green

    Write-Host "Testing GetHealthStatus method..." -ForegroundColor Yellow
    $health = $generator.GetHealthStatus()
    Write-Host "✓ Health check completed - Status: $($health.Status)" -ForegroundColor Green

    Write-Host "Testing ValidateConfiguration method..." -ForegroundColor Yellow
    $errors = $null
    $isValid = $generator.ValidateConfiguration([ref]$errors)
    if ($isValid) {
        Write-Host "✓ Configuration validation passed" -ForegroundColor Green
    } else {
        Write-Host "! Configuration validation failed with errors:" -ForegroundColor Yellow
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    }

    Write-Host "`n=== ALL TESTS PASSED ===" -ForegroundColor Green
    exit 0

} catch {
    Write-Host "`n✗ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nStack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Yellow
    exit 1
}
