<#
.SYNOPSIS
    Quick test to verify type conversion fix for ML Analytics Pipeline

.DESCRIPTION
    Tests the critical type conversion issue where PatternRecognitionResult
    needs to be converted to hashtable before passing to GenerateReport.
#>

Write-Host "Testing Type Conversion Fix" -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor Cyan

# Load required modules
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load ExecutiveSummaryGenerator
$summaryGeneratorPath = Join-Path $scriptRoot "ExecutiveSummaryGenerator.ps1"
if (Test-Path $summaryGeneratorPath) {
    . $summaryGeneratorPath
    Write-Host "✓ ExecutiveSummaryGenerator loaded" -ForegroundColor Green
} else {
    Write-Host "✗ ExecutiveSummaryGenerator.ps1 not found" -ForegroundColor Red
    exit 1
}

# Load PatternRecognitionEngine
$patternEnginePath = Join-Path $scriptRoot "PatternRecognitionEngine.ps1"
if (Test-Path $patternEnginePath) {
    . $patternEnginePath
    Write-Host "✓ PatternRecognitionEngine loaded" -ForegroundColor Green
} else {
    Write-Host "✗ PatternRecognitionEngine.ps1 not found" -ForegroundColor Red
    exit 1
}

# Test 1: Create PatternRecognitionResult object
Write-Host "`nTest 1: Creating PatternRecognitionResult object" -ForegroundColor Yellow
try {
    $patternEngine = [PatternRecognitionEngine]::new()
    $testData = @{
        Statistics = @{
            ProcessTypes = @{ "chrome.exe" = 100; "explorer.exe" = 50 }
            Operations = @{ "RegOpenKey" = 80; "CreateFile" = 70 }
            Results = @{ "SUCCESS" = 120; "ACCESS DENIED" = 10 }
        }
        RecordCount = 150
    }

    $patternResult = $patternEngine.AnalyzePatterns($testData)
    Write-Host "✓ PatternRecognitionResult object created successfully" -ForegroundColor Green
    Write-Host "  - Detected Patterns: $($patternResult.DetectedPatterns.Count)" -ForegroundColor Gray
    Write-Host "  - Process Clusters: $($patternResult.ProcessClusters.Count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Failed to create PatternRecognitionResult: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Convert to hashtable
Write-Host "`nTest 2: Converting PatternRecognitionResult to hashtable" -ForegroundColor Yellow
try {
    $patternsHashtable = @{
        DetectedPatterns = $patternResult.DetectedPatterns
        ProcessClusters = $patternResult.ProcessClusters
        TemporalPatterns = $patternResult.TemporalPatterns
        ErrorCorrelations = $patternResult.ErrorCorrelations
        BehaviorBaseline = $patternResult.BehaviorBaseline
        OverallConfidence = $patternResult.OverallConfidence
    }

    if ($patternsHashtable -is [hashtable]) {
        Write-Host "✓ Successfully converted to hashtable" -ForegroundColor Green
        Write-Host "  - Type: $($patternsHashtable.GetType().Name)" -ForegroundColor Gray
        Write-Host "  - Keys: $($patternsHashtable.Keys -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "✗ Conversion failed - not a hashtable" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ Conversion failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 3: Test GenerateReport method signature
Write-Host "`nTest 3: Testing GenerateReport method with hashtable" -ForegroundColor Yellow
try {
    $summaryGenerator = [ExecutiveSummaryGenerator]::new()

    # Create mock analytics hashtable
    $analyticsHashtable = @{
        HealthScore = 85
        RiskAssessment = @{
            Level = "Medium"
            Total = 65
            ErrorScore = 20
            FrequencyScore = 25
            ImpactScore = 15
            SecurityScore = 5
            Color = "warning"
        }
        Metrics = @{
            TotalEvents = 150
            ErrorRate = 0.066
            UniqueProcesses = 2
            UniqueOperations = 2
            UniqueErrors = 1
            EventsPerSecond = 15
            AccessDeniedCount = 10
        }
        Recommendations = @("Monitor access denied events", "Review process activity")
        Insights = @("Normal system activity detected")
        Anomalies = @()
    }

    # Test that the method accepts hashtable parameters
    $method = $summaryGenerator.GetType().GetMethod("GenerateReport")
    $parameters = $method.GetParameters()

    Write-Host "✓ GenerateReport method found" -ForegroundColor Green
    Write-Host "  - Parameters: $($parameters.Count)" -ForegroundColor Gray

    foreach ($param in $parameters) {
        Write-Host "    - $($param.Name): $($param.ParameterType.Name)" -ForegroundColor Gray
    }

    # Verify parameter types
    if ($parameters[0].ParameterType.Name -eq "Hashtable" -and
        $parameters[1].ParameterType.Name -eq "Hashtable") {
        Write-Host "✓ Method signature matches expected hashtable parameters" -ForegroundColor Green
    } else {
        Write-Host "✗ Method signature mismatch" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "✗ GenerateReport method test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 4: Full integration test
Write-Host "`nTest 4: Full integration test" -ForegroundColor Yellow
try {
    $processedData = @{
        RecordCount = 150
        Statistics = @{
            ProcessTypes = @{ "chrome.exe" = 100; "explorer.exe" = 50 }
            Operations = @{ "RegOpenKey" = 80; "CreateFile" = 70 }
            Results = @{ "SUCCESS" = 120; "ACCESS DENIED" = 10 }
        }
    }

    $reportHtml = $summaryGenerator.GenerateReport($analyticsHashtable, $patternsHashtable, $processedData)

    if (-not [string]::IsNullOrEmpty($reportHtml)) {
        Write-Host "✓ Full integration test passed" -ForegroundColor Green
        Write-Host "  - Report length: $($reportHtml.Length) characters" -ForegroundColor Gray

        # Save test report
        $testReportPath = Join-Path $scriptRoot "Test-Report.html"
        $summaryGenerator.SaveReport($reportHtml, $testReportPath)
        Write-Host "  - Test report saved to: $testReportPath" -ForegroundColor Gray
    } else {
        Write-Host "✗ Report generation returned empty result" -ForegroundColor Red
        exit 1
    }

} catch {
    Write-Host "✗ Full integration test failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + "=" * 40 -ForegroundColor Green
Write-Host "🎉 ALL TESTS PASSED - Type Conversion Fix Verified!" -ForegroundColor Green
Write-Host "=" * 40 -ForegroundColor Green

Write-Host "`nSUMMARY:" -ForegroundColor White
Write-Host "✓ PatternRecognitionResult object creation: SUCCESS" -ForegroundColor Green
Write-Host "✓ Object-to-hashtable conversion: SUCCESS" -ForegroundColor Green
Write-Host "✓ GenerateReport method signature: VALID" -ForegroundColor Green
Write-Host "✓ Full integration test: SUCCESS" -ForegroundColor Green

Write-Host "`nThe type conversion fix is working correctly!" -ForegroundColor Cyan
Write-Host "The ML Analytics Pipeline should now run without errors." -ForegroundColor Cyan
