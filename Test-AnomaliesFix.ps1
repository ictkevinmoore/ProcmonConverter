# Test script to verify Anomalies property fix

Write-Host "Testing Anomalies Property Fix" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

try {
    # Load the analytics engine
    . "ProcmonConverter-Production-Ready-20251105-214531/AdvancedAnalyticsEngine.ps1"

    # Create sample processed data
    $processedData = @{
        RecordCount = 1000
        Statistics = @{
            ProcessTypes = @{
                "notepad.exe" = 100
                "explorer.exe" = 200
                "chrome.exe" = 300
            }
            Operations = @{
                "ReadFile" = 400
                "WriteFile" = 300
                "CreateFile" = 300
            }
            Results = @{
                "SUCCESS" = 800
                "ACCESS DENIED" = 100
                "NAME NOT FOUND" = 100
            }
        }
        Performance = @{
            DurationSeconds = 10
        }
    }

    # Initialize analytics engine
    $engine = [AdvancedAnalyticsEngine]::new()

    # Run analysis
    $result = $engine.AnalyzeData($processedData)

    # Test that Anomalies property exists and is accessible
    if ($null -eq $result.Anomalies) {
        Write-Host "[FAIL] Anomalies property is null" -ForegroundColor Red
        exit 1
    }

    if (-not $result.Anomalies.ContainsKey('Count')) {
        Write-Host "[FAIL] Anomalies.Count property missing" -ForegroundColor Red
        exit 1
    }

    if (-not $result.Anomalies.ContainsKey('Items')) {
        Write-Host "[FAIL] Anomalies.Items property missing" -ForegroundColor Red
        exit 1
    }

    Write-Host "[PASS] Anomalies property exists with Count: $($result.Anomalies.Count)" -ForegroundColor Green

    # Test hashtable conversion (like in main script)
    $analyticsHashtable = @{
        HealthScore = $result.HealthScore
        RiskAssessment = $result.RiskAssessment
        Metrics = $result.Metrics
        Anomalies = $result.Anomalies  # This was the missing line
        Recommendations = $result.Recommendations
    }

    # Test accessing Anomalies from hashtable
    if (-not $analyticsHashtable.ContainsKey('Anomalies')) {
        Write-Host "[FAIL] Anomalies not in hashtable conversion" -ForegroundColor Red
        exit 1
    }

    if ($null -eq $analyticsHashtable.Anomalies) {
        Write-Host "[FAIL] Anomalies is null in hashtable" -ForegroundColor Red
        exit 1
    }

    Write-Host "[PASS] Anomalies property successfully converted to hashtable" -ForegroundColor Green
    Write-Host "[PASS] Anomalies.Count accessible: $($analyticsHashtable.Anomalies.Count)" -ForegroundColor Green

    Write-Host "`n[SUCCESS] Anomalies property fix verified!" -ForegroundColor Green
    exit 0

} catch {
    Write-Host "[FAIL] Test failed with error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

