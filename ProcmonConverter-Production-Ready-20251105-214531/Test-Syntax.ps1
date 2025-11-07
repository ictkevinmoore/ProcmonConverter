$ErrorActionPreference = 'Stop'
try {
    . ".\ExecutiveSummaryGenerator.ps1"
    Write-Host "SUCCESS: ExecutiveSummaryGenerator.ps1 loads without errors" -ForegroundColor Green

    # Try to instantiate the class
    $generator = [ExecutiveSummaryGenerator]::new()
    Write-Host "SUCCESS: ExecutiveSummaryGenerator class instantiated successfully" -ForegroundColor Green

    # Test health check
    $health = $generator.GetHealthStatus()
    Write-Host "SUCCESS: Health check executed - Status: $($health.Status)" -ForegroundColor Green

    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    exit 1
}
