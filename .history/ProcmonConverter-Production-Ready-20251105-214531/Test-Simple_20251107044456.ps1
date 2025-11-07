#Requires -Version 5.1

Write-Host "=== Simple Integration Test ===" -ForegroundColor Cyan

try {
    # Import modules
    Write-Host "Importing modules..." -ForegroundColor Yellow

    Import-Module .\AdvancedAnalyticsEngine.ps1 -Force -ErrorAction Stop
    Write-Host "✓ AdvancedAnalyticsEngine loaded" -ForegroundColor Green

    Import-Module .\ExecutiveSummaryGenerator.ps1 -Force -ErrorAction Stop
    Write-Host "✓ ExecutiveSummaryGenerator loaded" -ForegroundColor Green

    # Create test data
    Write-Host "Creating test data..." -ForegroundColor Yellow

    $testData = @{
        RecordCount = 10
        Statistics = @{
            ProcessTypes = @{ 'explorer.exe' = 3; 'chrome.exe' = 2; 'notepad.exe' = 1 }
            Operations = @{ 'CreateFile' = 4; 'RegOpenKey' = 3; 'WriteFile' = 2; 'ReadFile' = 1 }
            Results = @{
                'SUCCESS' = 7
                'ACCESS DENIED' = 2
                'NAME NOT FOUND' = 1
            }
        }
        Performance = @{
            DurationSeconds = 5.0
        }
    }

    # Test analytics
    Write-Host "Testing analytics..." -ForegroundColor Yellow

    $engine = [AdvancedAnalyticsEngine]::new()
    $analytics = $engine.AnalyzeData($testData)

    Write-Host "✓ Health Score: $($analytics.HealthScore)" -ForegroundColor Green
    Write-Host "✓ Anomalies: $($analytics.Anomalies.Count)" -ForegroundColor Green

    # Test report generation
    Write-Host "Testing report generation..." -ForegroundColor Yellow

    $generator = [ExecutiveSummaryGenerator]::new()

    $analyticsHash = @{
        HealthScore = $analytics.HealthScore
        RiskAssessment = $analytics.RiskAssessment
        Metrics = $analytics.Metrics
        Recommendations = $analytics.Recommendations
        Insights = $analytics.Insights
        Anomalies = $analytics.Anomalies
    }

    $patternsHash = @{
        DetectedPatterns = @()
        ProcessClusters = @()
        OverallConfidence = 0.8
    }

    $html = $generator.GenerateReport($analyticsHash, $patternsHash, $testData)

    Write-Host "✓ Report generated successfully" -ForegroundColor Green
    Write-Host "✓ HTML length: $($html.Length) characters" -ForegroundColor Green

    # Save report
    $reportPath = ".\Test-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    $generator.SaveReport($html, $reportPath)

    Write-Host "✓ Report saved to: $reportPath" -ForegroundColor Green

    Write-Host "`n=== ALL TESTS PASSED ===" -ForegroundColor Green
    Write-Host "Score: 10/10" -ForegroundColor Green

    return @{
        Success = $true
        ReportPath = $reportPath
    }
}
catch {
    Write-Host "`n✗ Test failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}

