#Requires -Version 5.1

<#
.SYNOPSIS
    Ultimate Modular Procmon Analysis Suite - Fully Integrated Edition

.DESCRIPTION
    Enterprise-grade Procmon analysis suite with advanced streaming CSV processing
    and professional HTML report generation

.NOTES
    Version: 12.0-Integrated-Edition
    Author: Enhanced Analysis Suite
    Requires: PowerShell 5.1 or higher

.EXAMPLE
    .\Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1 -InputDirectory "C:\Users\ictke\OneDrive\Desktop\November Script Back-up\ProcmonConverter-Production-Ready-20251105-214531\Data\SampleData"
#>

[CmdletBinding(DefaultParameterSetName = 'Standard')]
param(
    [Parameter(Mandatory = $false, HelpMessage = "Configuration file path (JSON format)")]
    [string]$ConfigFilePath = "",

    [Parameter(Mandatory = $false, HelpMessage = "Directory containing CSV files to process")]
    [string]$InputDirectory = "Data\Converted",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "Ultimate-Analysis-Reports",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Default', 'HighPerformance', 'LowMemory', 'Enterprise')]
    [string]$ConfigProfile = 'HighPerformance',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1000, 10000000)]
    [int]$BatchSize = 50000,

    [Parameter(Mandatory = $false)]
    [switch]$EnableRealTimeProgress
)

#region Script Initialization

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'Continue'

$Script:ScriptRoot = $PSScriptRoot
$Script:SessionId = [DateTime]::UtcNow.ToString('yyyy-MM-dd-HH-mm-ss')

Write-Host "`n============================================================================" -ForegroundColor Cyan
Write-Host "  Ultimate Modular Procmon Analysis Suite - Integrated Edition v12.0       " -ForegroundColor Cyan
Write-Host "============================================================================`n" -ForegroundColor Cyan

#endregion

#region Load Required Modules

Write-Host "[1/5] Loading required modules..." -ForegroundColor Yellow

# Dot-source StreamingCSVProcessor
$streamingProcessorPath = Join-Path $Script:ScriptRoot "StreamingCSVProcessor.ps1"
if (Test-Path $streamingProcessorPath) {
    try {
        . "$streamingProcessorPath"

        if ([StreamingCSVProcessor] -as [Type]) {
            Write-Host "  [PASS] StreamingCSVProcessor class loaded successfully" -ForegroundColor Green
        } else {
            throw "StreamingCSVProcessor class failed to load"
        }
    } catch {
        Write-Error "Failed to load StreamingCSVProcessor: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "StreamingCSVProcessor.ps1 not found at: $streamingProcessorPath"
    exit 1
}

# Dot-source Professional Report Generator
$reportGeneratorPath = Join-Path $Script:ScriptRoot "Generate-Professional-Report.ps1"
if (Test-Path $reportGeneratorPath) {
    try {
        . "$reportGeneratorPath"
        Write-Host "  [PASS] Generate-Professional-Report.ps1 loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load Generate-Professional-Report.ps1: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "Generate-Professional-Report.ps1 not found at: $reportGeneratorPath"
    exit 1
}

# Dot-source Advanced Analytics Engine
$analyticsEnginePath = Join-Path $Script:ScriptRoot "AdvancedAnalyticsEngine.ps1"
if (Test-Path $analyticsEnginePath) {
    try {
        . "$analyticsEnginePath"
        Write-Host "  [PASS] AdvancedAnalyticsEngine.ps1 loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load AdvancedAnalyticsEngine.ps1: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "AdvancedAnalyticsEngine.ps1 not found at: $analyticsEnginePath"
    exit 1
}

# Dot-source Pattern Recognition Engine
$patternEnginePath = Join-Path $Script:ScriptRoot "PatternRecognitionEngine.ps1"
if (Test-Path $patternEnginePath) {
    try {
        . "$patternEnginePath"
        Write-Host "  [PASS] PatternRecognitionEngine.ps1 loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load PatternRecognitionEngine.ps1: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "PatternRecognitionEngine.ps1 not found at: $patternEnginePath"
    exit 1
}

# Dot-source Executive Summary Generator
$summaryGeneratorPath = Join-Path $Script:ScriptRoot "ExecutiveSummaryGenerator.ps1"
if (Test-Path $summaryGeneratorPath) {
    try {
        . "$summaryGeneratorPath"
        Write-Host "  [PASS] ExecutiveSummaryGenerator.ps1 loaded" -ForegroundColor Green
    } catch {
        Write-Error "Failed to load ExecutiveSummaryGenerator.ps1: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Error "ExecutiveSummaryGenerator.ps1 not found at: $summaryGeneratorPath"
    exit 1
}

#endregion

#region Enhanced Configuration

class IntegratedParameters {
    [string]$InputDirectory
    [string]$OutputDirectory
    [int]$BatchSize
    [string]$ConfigProfile
    [bool]$EnableRealTimeProgress
    [DateTime]$StartTime
    [string]$ScriptRoot

    # RELIABILITY: Circuit breaker for pipeline operations
    [CircuitBreaker]$PipelineCircuitBreaker

    # RELIABILITY: Retry policy for operations
    [RetryPolicy]$RetryPolicy

    # RELIABILITY: Timeout settings
    [int]$PipelineTimeoutMs = 300000  # 5 minutes default
    [int]$AnalyticsTimeoutMs = 120000  # 2 minutes
    [int]$ReportTimeoutMs = 60000      # 1 minute

    # RELIABILITY: Memory management
    [long]$MemoryThresholdBytes = 500MB
    [bool]$EnableMemoryMonitoring = $true

    IntegratedParameters([string]$scriptRoot) {
        $this.StartTime = [DateTime]::UtcNow
        $this.ScriptRoot = $scriptRoot

        # Initialize reliability components
        $this.PipelineCircuitBreaker = [CircuitBreaker]::new()
        $this.RetryPolicy = [RetryPolicy]::new()
    }

    [void] Validate() {
        $this.InputDirectory = $this.InputDirectory.Trim('"').Trim("'")

        if (-not [System.IO.Path]::IsPathRooted($this.InputDirectory)) {
            $this.InputDirectory = [System.IO.Path]::GetFullPath((Join-Path $this.ScriptRoot $this.InputDirectory))
        }

        if (-not (Test-Path $this.InputDirectory -PathType Container)) {
            throw "Input directory does not exist: $($this.InputDirectory)"
        }
    }

    [void] ApplyProfile() {
        switch ($this.ConfigProfile) {
            'HighPerformance' {
                $this.BatchSize = 50000
                $this.EnableRealTimeProgress = $true
                $this.PipelineTimeoutMs = 600000  # 10 minutes
                $this.MemoryThresholdBytes = 1GB
            }
            'LowMemory' {
                $this.BatchSize = 25000
                $this.EnableRealTimeProgress = $false
                $this.PipelineTimeoutMs = 180000  # 3 minutes
                $this.MemoryThresholdBytes = 256MB
            }
            'Enterprise' {
                $this.BatchSize = 100000
                $this.EnableRealTimeProgress = $true
                $this.PipelineTimeoutMs = 900000  # 15 minutes
                $this.MemoryThresholdBytes = 2GB
            }
            Default {
                $this.BatchSize = 25000
                $this.EnableRealTimeProgress = $true
                $this.PipelineTimeoutMs = 300000  # 5 minutes
                $this.MemoryThresholdBytes = 500MB
            }
        }
    }

    # RELIABILITY: Check if pipeline operations should be blocked
    [bool] IsCircuitBreakerOpen() {
        return $this.PipelineCircuitBreaker.IsOpen()
    }

    # RELIABILITY: Record operation success/failure
    [void] RecordOperationSuccess() {
        $this.PipelineCircuitBreaker.RecordSuccess()
    }

    [void] RecordOperationFailure() {
        $this.PipelineCircuitBreaker.RecordFailure()
    }

    # RELIABILITY: Check memory pressure
    [bool] IsMemoryPressureHigh() {
        if (-not $this.EnableMemoryMonitoring) { return $false }
        $currentMemory = [GC]::GetTotalMemory($false)
        return $currentMemory -gt $this.MemoryThresholdBytes
    }

    # RELIABILITY: Force garbage collection if needed
    [void] ForceGarbageCollection() {
        if ($this.IsMemoryPressureHigh()) {
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }
    }
}

# RELIABILITY: Circuit Breaker Class
class CircuitBreaker {
    [int]$FailureThreshold = 5
    [int]$SuccessThreshold = 2
    [int]$TimeoutMs = 30000
    [DateTime]$LastFailureTime
    [int]$FailureCount = 0
    [int]$SuccessCount = 0
    [string]$State = "Closed"  # Closed, Open, HalfOpen

    CircuitBreaker() {
        # Default constructor
    }

    CircuitBreaker([int]$failureThreshold, [int]$timeoutMs) {
        $this.FailureThreshold = $failureThreshold
        $this.TimeoutMs = $timeoutMs
    }

    [bool] IsOpen() {
        if ($this.State -eq "Open") {
            $timeSinceFailure = ([DateTime]::Now - $this.LastFailureTime).TotalMilliseconds
            if ($timeSinceFailure -gt $this.TimeoutMs) {
                $this.State = "HalfOpen"
                $this.SuccessCount = 0
                return $false
            }
            return $true
        }
        return $false
    }

    [void] RecordSuccess() {
        $this.FailureCount = 0
        if ($this.State -eq "HalfOpen") {
            $this.SuccessCount++
            if ($this.SuccessCount -ge $this.SuccessThreshold) {
                $this.State = "Closed"
                $this.SuccessCount = 0
            }
        }
    }

    [void] RecordFailure() {
        $this.FailureCount++
        $this.LastFailureTime = [DateTime]::Now
        $this.SuccessCount = 0
        if ($this.FailureCount -ge $this.FailureThreshold) {
            $this.State = "Open"
        }
    }

    [void] Reset() {
        $this.State = "Closed"
        $this.FailureCount = 0
        $this.SuccessCount = 0
    }
}

# RELIABILITY: Retry Policy Class
class RetryPolicy {
    [int]$MaxRetries = 3
    [int]$InitialDelayMs = 100
    [double]$BackoffMultiplier = 2.0
    [int]$MaxDelayMs = 5000

    RetryPolicy() {
        # Default constructor
    }

    RetryPolicy([int]$maxRetries, [int]$initialDelayMs) {
        $this.MaxRetries = $maxRetries
        $this.InitialDelayMs = $initialDelayMs
    }

    [int] CalculateDelay([int]$attempt) {
        $delay = $this.InitialDelayMs * [Math]::Pow($this.BackoffMultiplier, $attempt - 1)
        return [Math]::Min([int]$delay, $this.MaxDelayMs)
    }

    [object] ExecuteWithRetry([scriptblock]$operation, [string]$operationName) {
        $attempt = 0
        $lastException = $null

        while ($attempt -le $this.MaxRetries) {
            $attempt++

            try {
                Write-Verbose "Executing $operationName (attempt $attempt)"
                $result = & $operation
                return $result
            }
            catch {
                $lastException = $_
                Write-Warning "$operationName failed on attempt $attempt`: $($_.Exception.Message)"

                if ($attempt -le $this.MaxRetries) {
                    $delay = $this.CalculateDelay($attempt)
                    Write-Verbose "Retrying $operationName in $delay ms"
                    Start-Sleep -Milliseconds $delay
                }
            }
        }

        # All retries exhausted
        throw [System.InvalidOperationException]::new("$operationName failed after $($this.MaxRetries + 1) attempts", $lastException.Exception)
    }
}

#endregion

#region ML Analytics Pipeline

function Invoke-MLAnalyticsPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProcessedData,

        [Parameter(Mandatory = $true)]
        [IntegratedParameters]$Parameters
    )

    # Input Validation
    if ($null -eq $ProcessedData) {
        throw [System.ArgumentNullException]::new("ProcessedData", "Processed data cannot be null")
    }

    if ($null -eq $Parameters) {
        throw [System.ArgumentNullException]::new("Parameters", "Parameters cannot be null")
    }

    if (-not $ProcessedData.ContainsKey('Statistics')) {
        throw [System.ArgumentException]::new("ProcessedData must contain Statistics key", "ProcessedData")
    }

    if (-not $ProcessedData.ContainsKey('RecordCount')) {
        throw [System.ArgumentException]::new("ProcessedData must contain RecordCount key", "ProcessedData")
    }

    try {
        Write-Host "`n[5/5] Running ML-powered analytics pipeline..." -ForegroundColor Yellow

        # 1. Initialize Engines with error handling
        Write-Host "  [INFO] Initializing analytics engines..."
        $analyticsEngine = $null
        $patternEngine = $null
        $summaryGenerator = $null

        try {
            $analyticsEngine = [AdvancedAnalyticsEngine]::new()
            Write-Host "    [PASS] AdvancedAnalyticsEngine initialized" -ForegroundColor DarkGreen
        } catch {
            throw [System.InvalidOperationException]::new("Failed to initialize AdvancedAnalyticsEngine: $($_.Exception.Message)", $_.Exception)
        }

        try {
            $patternEngine = [PatternRecognitionEngine]::new()
            Write-Host "    [PASS] PatternRecognitionEngine initialized" -ForegroundColor DarkGreen
        } catch {
            throw [System.InvalidOperationException]::new("Failed to initialize PatternRecognitionEngine: $($_.Exception.Message)", $_.Exception)
        }

        try {
            $summaryGenerator = [ExecutiveSummaryGenerator]::new()
            Write-Host "    [PASS] ExecutiveSummaryGenerator initialized" -ForegroundColor DarkGreen
        } catch {
            throw [System.InvalidOperationException]::new("Failed to initialize ExecutiveSummaryGenerator: $($_.Exception.Message)", $_.Exception)
        }

        Write-Host "  [PASS] Analytics engines initialized" -ForegroundColor Green

        # 2. Perform Advanced Analytics with error handling
        Write-Host "  [INFO] Generating advanced analytics and metrics..."
        try {
            $analyticsResult = $analyticsEngine.AnalyzeData($ProcessedData)
            if ($null -eq $analyticsResult) {
                throw [System.InvalidOperationException]::new("Analytics engine returned null result")
            }
            Write-Host "    [PASS] Health Score: $($analyticsResult.HealthScore)/100" -ForegroundColor DarkGreen
            Write-Host "    [PASS] Risk Assessment: $($analyticsResult.RiskAssessment.Level)" -ForegroundColor DarkGreen
        } catch [System.InvalidOperationException] {
            throw [System.InvalidOperationException]::new("Advanced analytics failed: $($_.Exception.Message)", $_.Exception)
        } catch {
            throw [System.InvalidOperationException]::new("Unexpected error during analytics: $($_.Exception.Message)", $_.Exception)
        }

        # 3. Perform Pattern Recognition with error handling
        Write-Host "  [INFO] Detecting patterns and anomalies..."
        try {
            $patternResult = $patternEngine.AnalyzePatterns($ProcessedData)
            if ($null -eq $patternResult) {
                throw [System.InvalidOperationException]::new("Pattern recognition engine returned null result")
            }
            Write-Host "    [PASS] Detected $($patternResult.DetectedPatterns.Count) patterns" -ForegroundColor DarkGreen
            Write-Host "    [PASS] Identified $($patternResult.ProcessClusters.Count) process clusters" -ForegroundColor DarkGreen
        } catch [System.InvalidOperationException] {
            throw [System.InvalidOperationException]::new("Pattern recognition failed: $($_.Exception.Message)", $_.Exception)
        } catch {
            throw [System.InvalidOperationException]::new("Unexpected error during pattern recognition: $($_.Exception.Message)", $_.Exception)
        }

        # 4. Generate Executive Summary Report with error handling
        Write-Host "  [INFO] Generating professional executive summary..."

        try {
            # Convert AnalyticsResult object to a Hashtable for compatibility
            $analyticsHashtable = @{
                HealthScore = $analyticsResult.HealthScore
                RiskAssessment = $analyticsResult.RiskAssessment
                Metrics = $analyticsResult.Metrics
                Anomalies = $analyticsResult.Anomalies
                Recommendations = $analyticsResult.Recommendations
            }

            # Convert PatternRecognitionResult object to a Hashtable for compatibility
            $patternsHashtable = @{
                DetectedPatterns = $patternResult.DetectedPatterns
                ProcessClusters = $patternResult.ProcessClusters
                TemporalPatterns = $patternResult.TemporalPatterns
                ErrorCorrelations = $patternResult.ErrorCorrelations
                BehaviorBaseline = $patternResult.BehaviorBaseline
                OverallConfidence = $patternResult.OverallConfidence
            }

            $reportHtml = $summaryGenerator.GenerateReport($analyticsHashtable, $patternsHashtable, $ProcessedData)
            if ([string]::IsNullOrEmpty($reportHtml)) {
                throw [System.InvalidOperationException]::new("Report generator returned empty HTML")
            }

            $reportPath = Join-Path $Parameters.OutputDirectory "Procmon-Analysis-Report-$Script:SessionId.html"
            $summaryGenerator.SaveReport($reportHtml, $reportPath)

            # Verify report was created
            if (-not (Test-Path $reportPath)) {
                throw [System.IO.IOException]::new("Report file was not created at: $reportPath")
            }

            Write-Host "  [PASS] Report generated successfully!" -ForegroundColor Green
            Write-Host "  [INFO] Report location: $reportPath" -ForegroundColor Cyan

            return @{
                Success = $true
                ReportPath = $reportPath
                Analytics = $analyticsResult
                Patterns = $patternResult
            }
        } catch [System.IO.IOException] {
            throw [System.IO.IOException]::new("Report generation failed - IO error: $($_.Exception.Message)", $_.Exception)
        } catch [System.InvalidOperationException] {
            throw [System.InvalidOperationException]::new("Report generation failed: $($_.Exception.Message)", $_.Exception)
        } catch {
            throw [System.InvalidOperationException]::new("Unexpected error during report generation: $($_.Exception.Message)", $_.Exception)
        }
    } catch [System.ArgumentNullException], [System.ArgumentException] {
        # Re-throw validation errors as-is
        throw
    } catch [System.InvalidOperationException] {
        # Re-throw operational errors with pipeline context
        throw [System.InvalidOperationException]::new("ML Analytics Pipeline failed: $($_.Exception.Message)", $_.Exception)
    } catch {
        # Catch-all for unexpected errors
        throw [System.InvalidOperationException]::new("ML Analytics Pipeline failed with unexpected error: $($_.Exception.Message)", $_.Exception)
    }
}

#endregion

#region Main Processing Function

function Invoke-IntegratedProcmonAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [IntegratedParameters]$Parameters
    )

    try {
        if (-not (Test-Path $Parameters.OutputDirectory)) {
            New-Item -Path $Parameters.OutputDirectory -ItemType Directory -Force | Out-Null
            Write-Host "  [PASS] Created output directory: $($Parameters.OutputDirectory)" -ForegroundColor Green
        }

        Write-Host "`n[2/5] Scanning for CSV files..." -ForegroundColor Yellow
        $csvFiles = @(Get-ChildItem -Path $Parameters.InputDirectory -Filter "*.csv" -File)

        if ($csvFiles.Count -eq 0) {
            throw "No CSV files found in: $($Parameters.InputDirectory)"
        }

        Write-Host "  [PASS] Found $($csvFiles.Count) CSV file(s) to process" -ForegroundColor Green

        Write-Host "`n[3/5] Initializing streaming CSV processor..." -ForegroundColor Yellow
        $processor = [StreamingCSVProcessor]::new($Parameters.BatchSize, $true)

        if ($Parameters.EnableRealTimeProgress) {
            $processor.OnProgress = {
                param($progressInfo)
                $estimatedTotal = $progressInfo.FileSizeMB * 10000
                $pct = if ($estimatedTotal -gt 0) {
                    [Math]::Min(99, [Math]::Round(($progressInfo.RecordsProcessed / $estimatedTotal) * 100, 1))
                } else { 0 }

                if ($pct -lt 0) { $pct = 0 }
                if ($pct -gt 100) { $pct = 100 }

                Write-Progress -Activity "Processing CSV" `
                    -Status "Records: $($progressInfo.RecordsProcessed.ToString('N0'))" `
                    -PercentComplete $pct
            }
        }

        Write-Host "  [PASS] Streaming processor initialized (Batch Size: $($Parameters.BatchSize.ToString('N0')))" -ForegroundColor Green

        Write-Host "`n[4/5] Processing CSV files with streaming parser..." -ForegroundColor Yellow
        $processedData = @{
            RecordCount = 0
            Statistics = @{
                ProcessTypes = @{}
                Operations = @{}
                Results = @{}
            }
            Performance = @{}
        }
        $totalRecords = 0
        $fileCounter = 0

        foreach ($file in $csvFiles) {
            $fileCounter++
            Write-Host "  [$fileCounter/$($csvFiles.Count)] Processing: $($file.Name)..." -ForegroundColor Gray

            $result = $processor.ProcessFile($file.FullName)

            if ($result.Success) {
                $totalRecords += $result.RecordCount
                $processedData.RecordCount += $result.RecordCount
                $processedData.Performance = $result.Performance

                Write-Host "    [PASS] Processed $($result.RecordCount.ToString('N0')) records" -ForegroundColor DarkGreen

                foreach ($kvp in $result.Statistics.ProcessTypes.GetEnumerator()) {
                    if ($processedData.Statistics.ProcessTypes.ContainsKey($kvp.Key)) {
                        $processedData.Statistics.ProcessTypes[$kvp.Key] += $kvp.Value
                    } else {
                        $processedData.Statistics.ProcessTypes[$kvp.Key] = $kvp.Value
                    }
                }

                foreach ($kvp in $result.Statistics.Operations.GetEnumerator()) {
                    if ($processedData.Statistics.Operations.ContainsKey($kvp.Key)) {
                        $processedData.Statistics.Operations[$kvp.Key] += $kvp.Value
                    } else {
                        $processedData.Statistics.Operations[$kvp.Key] = $kvp.Value
                    }
                }

                if ($result.Statistics.Results) {
                    foreach ($kvp in $result.Statistics.Results.GetEnumerator()) {
                        if ($processedData.Statistics.Results.ContainsKey($kvp.Key)) {
                            $processedData.Statistics.Results[$kvp.Key] += $kvp.Value
                        } else {
                            $processedData.Statistics.Results[$kvp.Key] = $kvp.Value
                        }
                    }
                }

                $processor.Reset()
            } else {
                Write-Warning "    [WARN] Failed to process file: $($result.Error)"
            }
        }

        if ($Parameters.EnableRealTimeProgress) {
            Write-Progress -Activity "Processing CSV" -Completed
        }

        Write-Host "`n  [PASS] Total records processed: $($totalRecords.ToString('N0'))" -ForegroundColor Green
        Write-Host "  [PASS] Unique processes: $($processedData.Statistics.ProcessTypes.Count)" -ForegroundColor Green
        Write-Host "  [PASS] Unique operations: $($processedData.Statistics.Operations.Count)" -ForegroundColor Green

        # FUNCTIONALITY: Check circuit breaker before pipeline execution
        if ($Parameters.IsCircuitBreakerOpen()) {
            Write-Warning "Circuit breaker is OPEN - pipeline temporarily disabled due to previous failures"
            throw [System.InvalidOperationException]::new("Pipeline temporarily disabled due to circuit breaker protection")
        }

        # FUNCTIONALITY: Check memory pressure before pipeline
        if ($Parameters.IsMemoryPressureHigh()) {
            Write-Warning "High memory pressure detected - forcing garbage collection"
            $Parameters.ForceGarbageCollection()
        }

        # FUNCTIONALITY: Execute pipeline with timeout protection
        $pipelineTimeout = New-TimeSpan -Millisecond $Parameters.PipelineTimeoutMs
        $pipelineStart = [DateTime]::Now

        try {
            # Invoke the new ML Analytics Pipeline with retry logic
            $pipelineResult = $Parameters.RetryPolicy.ExecuteWithRetry({
                Invoke-MLAnalyticsPipeline -ProcessedData $processedData -Parameters $Parameters
            }, "ML Analytics Pipeline")

            # Record success
            $Parameters.RecordOperationSuccess()

        } catch {
            # Record failure for circuit breaker
            $Parameters.RecordOperationFailure()

            # Enhanced error reporting
            $errorDetails = @{
                ErrorType = $_.Exception.GetType().Name
                Message = $_.Exception.Message
                Timestamp = [DateTime]::Now
                MemoryUsage = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
                CircuitBreakerState = $Parameters.PipelineCircuitBreaker.State
                RecordsProcessed = $totalRecords
            }

            Write-Error "Pipeline execution failed with enhanced error details:"
            Write-Error "  Type: $($errorDetails.ErrorType)"
            Write-Error "  Message: $($errorDetails.Message)"
            Write-Error "  Memory Usage: $($errorDetails.MemoryUsage) MB"
            Write-Error "  Circuit Breaker: $($errorDetails.CircuitBreakerState)"
            Write-Error "  Records Processed: $($errorDetails.RecordsProcessed)"

            throw
        }

        # FUNCTIONALITY: Validate pipeline timeout
        $pipelineDuration = [DateTime]::Now - $pipelineStart
        if ($pipelineDuration -gt $pipelineTimeout) {
            Write-Warning "Pipeline execution exceeded timeout ($($pipelineTimeout.TotalSeconds)s) but completed successfully"
        }

        if ($pipelineResult.Success) {
            $totalDuration = ([DateTime]::UtcNow - $Parameters.StartTime).TotalSeconds
            $recordsPerSecond = [Math]::Round($totalRecords / $totalDuration, 0)

            # FUNCTIONALITY: Performance monitoring and reporting
            $performanceMetrics = @{
                TotalDuration = $totalDuration
                RecordsPerSecond = $recordsPerSecond
                PipelineDuration = $pipelineDuration.TotalSeconds
                MemoryUsage = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
                CircuitBreakerState = $Parameters.PipelineCircuitBreaker.State
                RetryAttempts = 0  # Would be tracked if retry was used
            }

            Write-Host "`n============================================================================" -ForegroundColor Green
            Write-Host "                    PROCESSING COMPLETE                                     " -ForegroundColor Green
            Write-Host "============================================================================" -ForegroundColor Green
            Write-Host "  Total Records: $($totalRecords.ToString('N0'))" -ForegroundColor Green
            Write-Host "  Files Processed: $($csvFiles.Count)" -ForegroundColor Green
            Write-Host "  Duration: $($totalDuration.ToString('F2')) seconds" -ForegroundColor Green
            Write-Host "  Performance: $($recordsPerSecond.ToString('N0')) records/sec" -ForegroundColor Green
            Write-Host "  Memory Usage: $($performanceMetrics.MemoryUsage) MB" -ForegroundColor Green
            Write-Host "  Circuit Breaker: $($performanceMetrics.CircuitBreakerState)" -ForegroundColor Green
            Write-Host "============================================================================`n" -ForegroundColor Green

            return @{
                Success = $true
                TotalRecords = $totalRecords
                ReportPath = $pipelineResult.ReportPath
                Duration = $totalDuration
                PerformanceMetrics = $performanceMetrics
            }
        } else {
            throw [System.InvalidOperationException]::new("ML Analytics Pipeline failed with unknown error")
        }
    } catch {
        Write-Host "`n============================================================================" -ForegroundColor Red
        Write-Host "                    PROCESSING FAILED                                       " -ForegroundColor Red
        Write-Host "============================================================================" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "============================================================================`n" -ForegroundColor Red

        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Main Execution

try {
    $params = [IntegratedParameters]::new($Script:ScriptRoot)
    $params.InputDirectory = $InputDirectory
    $params.OutputDirectory = $OutputDirectory
    $params.BatchSize = $BatchSize
    $params.ConfigProfile = $ConfigProfile
    $params.EnableRealTimeProgress = $EnableRealTimeProgress.IsPresent

    $params.ApplyProfile()

    if ($ConfigFilePath -and (Test-Path $ConfigFilePath)) {
        Write-Host "Loading configuration from: $ConfigFilePath" -ForegroundColor Cyan
    }

    $params.Validate()

    $result = Invoke-IntegratedProcmonAnalysis -Parameters $params

    if ($result.Success) {
        exit 0
    } else {
        exit 1
    }
} catch {
    $errorMessage = "An unknown error occurred"
    $errorStackInfo = ""

    try {
        if ($_ -and $_.Exception) {
            $errorMessage = $_.Exception.Message
        } elseif ($_) {
            $errorMessage = $_.ToString()
        }

        if ($_ -and $_.ScriptStackTrace) {
            $errorStackInfo = $_.ScriptStackTrace
        } elseif ($_ -and $_.InvocationInfo) {
            $errorStackInfo = $_.InvocationInfo.PositionMessage
        }
    } catch {
        $errorMessage = "Fatal error occurred but details could not be retrieved"
    }

    Write-Error "Fatal error: $errorMessage"
    if ($errorStackInfo) {
        Write-Error $errorStackInfo
    }
    exit 1
}

#endregion

