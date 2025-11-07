#Requires -Version 5.1

<#
.SYNOPSIS
    Executive Summary Generator with Professional HTML Dashboard

.DESCRIPTION
    Generates comprehensive executive summaries and interactive HTML dashboards
    with Bootstrap 5, Chart.js visualizations, and natural language insights.
    Integrates with AdvancedAnalyticsEngine and PatternRecognitionEngine.

.NOTES
    Version: 1.0
    Author: Enhanced Analysis Suite

.EXAMPLE
    $generator = [ExecutiveSummaryGenerator]::new()

    # Convert objects to hashtables for compatibility with GenerateReport method
    $analyticsHashtable = @{
        HealthScore = $analytics.HealthScore
        RiskAssessment = $analytics.RiskAssessment
        Metrics = $analytics.Metrics
        Recommendations = $analytics.Recommendations
        Insights = $analytics.Insights
        Anomalies = $analytics.Anomalies
    }

    $patternsHashtable = @{
        DetectedPatterns = $patterns.DetectedPatterns
        ProcessClusters = $patterns.ProcessClusters
        TemporalPatterns = $patterns.TemporalPatterns
        ErrorCorrelations = $patterns.ErrorCorrelations
        BehaviorBaseline = $patterns.BehaviorBaseline
        OverallConfidence = $patterns.OverallConfidence
    }

    $html = $generator.GenerateReport($analyticsHashtable, $patternsHashtable, $processedData)
    $generator.SaveReport($html, "ProcmonAnalysis-Report.html")
#>

using namespace System.Collections.Generic
using namespace System.Text
using namespace System.IO
using namespace System.Threading

#region Error Handling Infrastructure

# ENHANCEMENT: Error severity levels for structured logging
enum ErrorSeverity {
    Trace = 0
    Debug = 1
    Info = 2
    Warning = 3
    Error = 4
    Critical = 5
    Fatal = 6
}

# ENHANCEMENT: Error categories for classification
enum ErrorCategory {
    Unknown = 0
    Input = 1
    Processing = 2
    Output = 3
    Configuration = 4
    Network = 5
    Security = 6
    Performance = 7
}

# ENHANCEMENT: Detailed error information class
class ErrorDetail {
    [ErrorSeverity]$Severity
    [ErrorCategory]$Category
    [string]$Message
    [string]$ErrorCode
    [DateTime]$Timestamp
    [string]$StackTrace
    [string]$Source
    [hashtable]$Context

    ErrorDetail([ErrorSeverity]$severity, [ErrorCategory]$category, [string]$message) {
        $this.Severity = $severity
        $this.Category = $category
        $this.Message = $message
        $this.ErrorCode = "$($category).$($severity).$(Get-Random -Minimum 1000 -Maximum 9999)"
        $this.Timestamp = [DateTime]::Now
        $this.Context = @{}
    }

    [string] ToString() {
        $contextStr = if ($this.Context.Count -gt 0) {
            " | Context: $($this.Context.Keys | ForEach-Object { "$_=$($this.Context[$_])" } | Join-String -Separator ', ')"
        } else { "" }
        return "[$($this.Severity)] [$($this.Category)] $($this.Message)$contextStr"
    }
}

# ENHANCEMENT: Retry policy configuration
class RetryPolicy {
    [int]$MaxRetries = 3
    [int]$InitialDelayMs = 100
    [double]$BackoffMultiplier = 2.0
    [int]$MaxDelayMs = 5000

    [int] CalculateDelay([int]$attempt) {
        $delay = $this.InitialDelayMs * [Math]::Pow($this.BackoffMultiplier, $attempt - 1)
        return [Math]::Min([int]$delay, $this.MaxDelayMs)
    }
}

# ENHANCEMENT: Circuit Breaker Pattern for reliability
class CircuitBreaker {
    [int]$FailureThreshold = 5
    [int]$SuccessThreshold = 2
    [int]$TimeoutMs = 30000
    [DateTime]$LastFailureTime
    [int]$FailureCount = 0
    [int]$SuccessCount = 0
    [string]$State = "Closed"  # Closed, Open, HalfOpen

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

# ENHANCEMENT: Cache entry with TTL support
class CacheEntry {
    [object]$Value
    [DateTime]$ExpirationTime
    [int]$AccessCount = 0

    CacheEntry([object]$value, [int]$ttlSeconds) {
        $this.Value = $value
        $this.ExpirationTime = [DateTime]::Now.AddSeconds($ttlSeconds)
    }

    [bool] IsExpired() {
        return [DateTime]::Now -gt $this.ExpirationTime
    }

    [void] UpdateAccess() {
        $this.AccessCount++
    }
}

# ENHANCEMENT: Health check status
class HealthCheckResult {
    [bool]$IsHealthy
    [string]$Status
    [hashtable]$Metrics
    [DateTime]$CheckTime
    [string[]]$Messages

    HealthCheckResult() {
        $this.IsHealthy = $true
        $this.Status = "Healthy"
        $this.Metrics = @{}
        $this.CheckTime = [DateTime]::Now
        $this.Messages = @()
    }
}

#endregion

#region Report Configuration

class ReportConfiguration {
    [string]$Title = "Procmon Professional Analysis Report"
    [string]$CompanyName = "System Analysis Team"
    [bool]$IncludeCharts = $true
    [bool]$IncludeDetailedTables = $true
    [bool]$IncludeExecutiveSummary = $true
    [bool]$IncludeRecommendations = $true
    [bool]$DarkMode = $false
    [string]$PrimaryColor = "#0d6efd"
    [string]$SuccessColor = "#198754"
    [string]$WarningColor = "#ffc107"
    [string]$DangerColor = "#dc3545"
    [string]$InfoColor = "#0dcaf0"

    # NEW: Summary depth and mode configuration
    [ValidateSet("Brief", "Standard", "Detailed")]
    [string]$SummaryDepth = "Standard"

    [ValidateSet("Executive", "Technical")]
    [string]$SummaryMode = "Executive"

    # ENHANCEMENT: Logging configuration
    [bool]$EnableLogging = $false
    [ValidateSet("Trace", "Debug", "Info", "Warning", "Error", "Critical", "Fatal")]
    [string]$LogLevel = "Info"
    [string]$LogPath = ""

    ReportConfiguration() {
        # Default constructor
    }
}

#endregion

#region Executive Summary Generator

class ExecutiveSummaryGenerator {
    [ReportConfiguration]$Config
    [hashtable]$Templates

    # OPTIMIZATION: Caching and performance tracking
    [Dictionary[string,string]]$ReportCache
    [Dictionary[string,hashtable]]$ChartDataCache
    [bool]$EnableCaching = $true
    [int]$CacheSize = 100
    [System.Diagnostics.Stopwatch]$Stopwatch

    # ENHANCEMENT: Error logging infrastructure
    [List[ErrorDetail]]$ErrorLog
    [ReaderWriterLockSlim]$ErrorLogLock
    [int]$MaxErrorLogSize = 1000

    # ENHANCEMENT: Retry policy
    [RetryPolicy]$RetryPolicy

    # ENHANCEMENT: Performance tracking
    [bool]$EnablePerformanceTracking = $false
    [Dictionary[string,List[double]]]$PerformanceMetrics

    # ENHANCEMENT: Circuit breaker for reliability
    [CircuitBreaker]$CircuitBreaker

    # ENHANCEMENT: Cache with TTL support
    [Dictionary[string,CacheEntry]]$ReportCacheTTL
    [Dictionary[string,CacheEntry]]$ChartDataCacheTTL
    [int]$CacheTTLSeconds = 3600  # 1 hour default

    # ENHANCEMENT: Timeout configuration
    [int]$ReportGenerationTimeoutMs = 60000
    [int]$ChartGenerationTimeoutMs = 30000

    # ENHANCEMENT: Telemetry hooks
    [scriptblock]$OnTelemetryEvent
    [bool]$EnableTelemetry = $false

    # ENHANCEMENT: Memory pressure detection
    [long]$MemoryThresholdBytes = 500MB
    [bool]$EnableMemoryMonitoring = $true

    ExecutiveSummaryGenerator() {
        $this.Config = [ReportConfiguration]::new()
        $this.Templates = @{}
        $this.InitializeTemplates()

        # OPTIMIZATION: Initialize caching
        $this.ReportCache = [Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ChartDataCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ReportCacheTTL = [Dictionary[string,CacheEntry]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ChartDataCacheTTL = [Dictionary[string,CacheEntry]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()

        # ENHANCEMENT: Initialize error logging
        $this.ErrorLog = [List[ErrorDetail]]::new()
        $this.ErrorLogLock = [ReaderWriterLockSlim]::new()
        $this.RetryPolicy = [RetryPolicy]::new()
        $this.PerformanceMetrics = [Dictionary[string,List[double]]]::new([StringComparer]::OrdinalIgnoreCase)

        # ENHANCEMENT: Initialize circuit breaker
        $this.CircuitBreaker = [CircuitBreaker]::new()
    }

    ExecutiveSummaryGenerator([ReportConfiguration]$config) {
        $this.Config = $config
        $this.Templates = @{}
        $this.InitializeTemplates()

        # OPTIMIZATION: Initialize caching
        $this.ReportCache = [Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ChartDataCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ReportCacheTTL = [Dictionary[string,CacheEntry]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ChartDataCacheTTL = [Dictionary[string,CacheEntry]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()

        # ENHANCEMENT: Initialize error logging
        $this.ErrorLog = [List[ErrorDetail]]::new()
        $this.ErrorLogLock = [ReaderWriterLockSlim]::new()
        $this.RetryPolicy = [RetryPolicy]::new()
        $this.PerformanceMetrics = [Dictionary[string,List[double]]]::new([StringComparer]::OrdinalIgnoreCase)

        # ENHANCEMENT: Initialize circuit breaker
        $this.CircuitBreaker = [CircuitBreaker]::new()
    }

    # ENHANCEMENT: Comprehensive logging methods
    hidden [void] LogTrace([string]$message, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Trace, [ErrorCategory]::Unknown, $message, $null, $context, $false)
    }

    hidden [void] LogDebug([string]$message, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Debug, [ErrorCategory]::Unknown, $message, $null, $context, $false)
    }

    hidden [void] LogInfo([string]$message, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Info, [ErrorCategory]::Unknown, $message, $null, $context, $false)
    }

    hidden [void] LogWarning([string]$message, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Warning, [ErrorCategory]::Unknown, $message, $null, $context, $false)
    }

    hidden [void] LogError([string]$message, [Exception]$exception, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Error, [ErrorCategory]::Processing, $message, $exception, $context, $true)
    }

    hidden [void] LogCritical([string]$message, [Exception]$exception, [hashtable]$context = @{}) {
        $this.Log([ErrorSeverity]::Critical, [ErrorCategory]::Processing, $message, $exception, $context, $true)
    }

    hidden [void] Log([ErrorSeverity]$severity, [ErrorCategory]$category, [string]$message, [Exception]$exception, [hashtable]$context, [bool]$isError) {
        try {
            if (-not $this.Config.EnableLogging) { return }

            # Check log level
            $logLevels = @("Trace", "Debug", "Info", "Warning", "Error", "Critical", "Fatal")
            $currentLevelIndex = [array]::IndexOf($logLevels, $this.Config.LogLevel)
            $messageLevelIndex = [array]::IndexOf($logLevels, $severity.ToString())

            if ($messageLevelIndex -lt $currentLevelIndex) { return }

            $errorDetail = [ErrorDetail]::new($severity, $category, $message)

            if ($exception) {
                $errorDetail.StackTrace = $exception.StackTrace
                $errorDetail.Source = $exception.Source
                $errorDetail.Context["ExceptionType"] = $exception.GetType().Name
                $errorDetail.Context["ExceptionMessage"] = $exception.Message
            }

            foreach ($key in $context.Keys) {
                $errorDetail.Context[$key] = $context[$key]
            }

            # Thread-safe logging
            $this.ErrorLogLock.EnterWriteLock()
            try {
                if ($this.ErrorLog.Count -ge $this.MaxErrorLogSize) {
                    $this.ErrorLog.RemoveAt(0)
                }
                $this.ErrorLog.Add($errorDetail)
            }
            finally {
                $this.ErrorLogLock.ExitWriteLock()
            }

            # Console output
            if ($isError) {
                Write-Error $errorDetail.ToString()
            } else {
                Write-Verbose $errorDetail.ToString()
            }

            # File logging if path is configured
            if (-not [string]::IsNullOrWhiteSpace($this.Config.LogPath)) {
                $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') $($errorDetail.ToString())"
                if ($errorDetail.StackTrace) {
                    $logEntry += "`n  StackTrace: $($errorDetail.StackTrace)"
                }
                Add-Content -Path $this.Config.LogPath -Value $logEntry
            }
        }
        catch {
            # Fallback logging
            Write-Warning "Logging failed: $($_.Exception.Message)"
        }
    }

    # ENHANCEMENT: Retry execution with exponential backoff
    hidden [object] ExecuteWithRetry([scriptblock]$operation, [string]$operationName, [hashtable]$context = @{}) {
        $attempt = 0
        $lastException = $null

        while ($attempt -le $this.RetryPolicy.MaxRetries) {
            $attempt++

            try {
                $this.LogTrace("Executing $operationName (attempt $attempt)", $context)
                $result = & $operation

                if ($attempt -gt 1) {
                    $this.LogInfo("$operationName succeeded after $attempt attempts", $context)
                }

                return $result
            }
            catch {
                $lastException = $_
                $context["Attempt"] = $attempt
                $this.LogWarning("$operationName failed on attempt $attempt", $context)

                if ($attempt -le $this.RetryPolicy.MaxRetries) {
                    $delay = $this.RetryPolicy.CalculateDelay($attempt)
                    $this.LogDebug("Retrying $operationName in $delay ms", $context)
                    Start-Sleep -Milliseconds $delay
                }
            }
        }

        # All retries exhausted
        $this.LogError("$operationName failed after $($this.RetryPolicy.MaxRetries + 1) attempts", $lastException, $context)
        throw $lastException
    }

    # ENHANCEMENT: Input validation helper
    hidden [bool] ValidateInput([string]$paramName, [object]$value, [string]$expectedType, [ref]$errorMessage) {
        try {
            if ($null -eq $value) {
                $errorMessage.Value = "$paramName cannot be null"
                return $false
            }

            $actualType = $value.GetType().Name

            if ($expectedType -eq "hashtable" -and $value -isnot [hashtable]) {
                $errorMessage.Value = "$paramName must be a hashtable (got: $actualType)"
                return $false
            }

            if ($expectedType -eq "string" -and $value -isnot [string]) {
                $errorMessage.Value = "$paramName must be a string (got: $actualType)"
                return $false
            }

            return $true
        }
        catch {
            $errorMessage.Value = "Validation error for ${paramName}: $($_.Exception.Message)"
            return $false
        }
    }

    # ENHANCEMENT: Sanitize user inputs
    hidden [string] SanitizeString([string]$input) {
        if ([string]::IsNullOrEmpty($input)) {
            return ""
        }

        # Remove potentially dangerous HTML/script content
        $sanitized = $input -replace '<script[^>]*>.*?</script>', ''
        $sanitized = $sanitized -replace '<iframe[^>]*>.*?</iframe>', ''
        $sanitized = $sanitized -replace 'javascript:', ''
        $sanitized = $sanitized -replace 'on\w+\s*=', ''

        # Encode HTML special characters
        $sanitized = [System.Web.HttpUtility]::HtmlEncode($sanitized)

        return $sanitized
    }

    # ENHANCEMENT: Track performance metrics
    hidden [void] RecordMetric([string]$operation, [double]$durationMs) {
        if (-not $this.EnablePerformanceTracking) { return }

        try {
            if (-not $this.PerformanceMetrics.ContainsKey($operation)) {
                $this.PerformanceMetrics[$operation] = [List[double]]::new()
            }

            $this.PerformanceMetrics[$operation].Add($durationMs)

            # Keep only last 100 measurements per operation
            if ($this.PerformanceMetrics[$operation].Count -gt 100) {
                $this.PerformanceMetrics[$operation].RemoveAt(0)
            }
        }
        catch {
            $this.LogWarning("Failed to record metric for $operation", @{ Duration = $durationMs })
        }
    }

    # ENHANCEMENT: Get performance statistics
    [hashtable] GetPerformanceStats() {
        $stats = @{}

        foreach ($operation in $this.PerformanceMetrics.Keys) {
            $measurements = $this.PerformanceMetrics[$operation]
            if ($measurements.Count -gt 0) {
                $stats[$operation] = @{
                    Count = $measurements.Count
                    Average = ($measurements | Measure-Object -Average).Average
                    Min = ($measurements | Measure-Object -Minimum).Minimum
                    Max = ($measurements | Measure-Object -Maximum).Maximum
                    Last = $measurements[$measurements.Count - 1]
                }
            }
        }

        return $stats
    }

    # ENHANCEMENT: Get error summary
    [hashtable] GetErrorSummary() {
        $summary = @{
            TotalErrors = 0
            BySeverity = @{}
            ByCategory = @{}
            RecentErrors = @()
        }

        $this.ErrorLogLock.EnterReadLock()
        try {
            $summary.TotalErrors = $this.ErrorLog.Count

            $summary.BySeverity = $this.ErrorLog | Group-Object -Property Severity | ForEach-Object {
                @{ $_.Name = $_.Count }
            } | ForEach-Object { $_ }

            $summary.ByCategory = $this.ErrorLog | Group-Object -Property Category | ForEach-Object {
                @{ $_.Name = $_.Count }
            } | ForEach-Object { $_ }

            $summary.RecentErrors = $this.ErrorLog | Select-Object -Last 10 | ForEach-Object {
                @{
                    Severity = $_.Severity.ToString()
                    Category = $_.Category.ToString()
                    Message = $_.Message
                    Timestamp = $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                    ErrorCode = $_.ErrorCode
                }
            }
        }
        finally {
            $this.ErrorLogLock.ExitReadLock()
        }

        return $summary
    }

    # ENHANCEMENT: Comprehensive health check
    [HealthCheckResult] GetHealthStatus() {
        $health = [HealthCheckResult]::new()

        try {
            # Check cache health
            $currentCacheSize = $this.ReportCache.Count + $this.ChartDataCache.Count
            $health.Metrics["CacheSize"] = $currentCacheSize

            if ($currentCacheSize -gt $this.CacheSize * 0.9) {
                $health.Messages += "Cache near capacity: $currentCacheSize/$($this.CacheSize)"
            }

            # Check memory pressure
            if ($this.EnableMemoryMonitoring) {
                $memoryUsage = [GC]::GetTotalMemory($false)
                $health.Metrics["MemoryUsageMB"] = [Math]::Round($memoryUsage / 1MB, 2)

                if ($memoryUsage -gt $this.MemoryThresholdBytes) {
                    $health.IsHealthy = $false
                    $health.Status = "Degraded"
                    $health.Messages += "High memory usage: $([Math]::Round($memoryUsage / 1MB, 2)) MB"
                }
            }

            # Check circuit breaker status
            $health.Metrics["CircuitBreakerState"] = $this.CircuitBreaker.State
            if ($this.CircuitBreaker.State -eq "Open") {
                $health.IsHealthy = $false
                $health.Status = "Unhealthy"
                $health.Messages += "Circuit breaker is OPEN - operations blocked"
            }

            # Check error rate
            $this.ErrorLogLock.EnterReadLock()
            try {
                $errorCount = $this.ErrorLog.Count
                $health.Metrics["ErrorCount"] = $errorCount

                if ($errorCount -gt $this.MaxErrorLogSize * 0.8) {
                    $health.Status = "Degraded"
                    $health.Messages += "High error count: $errorCount"
                }
            }
            finally {
                $this.ErrorLogLock.ExitReadLock()
            }

            # Performance metrics
            if ($this.EnablePerformanceTracking -and $this.PerformanceMetrics.Count -gt 0) {
                $avgTimes = @{}
                foreach ($op in $this.PerformanceMetrics.Keys) {
                    $measurements = $this.PerformanceMetrics[$op]
                    if ($measurements.Count -gt 0) {
                        $avgTimes[$op] = [Math]::Round(($measurements | Measure-Object -Average).Average, 2)
                    }
                }
                $health.Metrics["AverageOperationTimes"] = $avgTimes
            }

            if ($health.IsHealthy) {
                $health.Messages += "All systems operational"
            }
        }
        catch {
            $health.IsHealthy = $false
            $health.Status = "Error"
            $health.Messages += "Health check failed: $($_.Exception.Message)"
        }

        return $health
    }

    # ENHANCEMENT: Clean expired cache entries
    hidden [void] CleanExpiredCache() {
        try {
            # Clean report cache TTL
            $expiredKeys = [List[string]]::new()
            foreach ($key in $this.ReportCacheTTL.Keys) {
                if ($this.ReportCacheTTL[$key].IsExpired()) {
                    $expiredKeys.Add($key)
                }
            }
            foreach ($key in $expiredKeys) {
                $this.ReportCacheTTL.Remove($key) | Out-Null
                if ($this.ReportCache.ContainsKey($key)) {
                    $this.ReportCache.Remove($key) | Out-Null
                }
            }

            # Clean chart cache TTL
            $expiredKeys.Clear()
            foreach ($key in $this.ChartDataCacheTTL.Keys) {
                if ($this.ChartDataCacheTTL[$key].IsExpired()) {
                    $expiredKeys.Add($key)
                }
            }
            foreach ($key in $expiredKeys) {
                $this.ChartDataCacheTTL.Remove($key) | Out-Null
                if ($this.ChartDataCache.ContainsKey($key)) {
                    $this.ChartDataCache.Remove($key) | Out-Null
                }
            }

            if ($expiredKeys.Count -gt 0) {
                $this.LogDebug("Cleaned $($expiredKeys.Count) expired cache entries")
            }
        }
        catch {
            $this.LogWarning("Failed to clean expired cache: $($_.Exception.Message)")
        }
    }

    # ENHANCEMENT: Check memory pressure
    hidden [bool] IsMemoryPressureHigh() {
        if (-not $this.EnableMemoryMonitoring) { return $false }

        $currentMemory = [GC]::GetTotalMemory($false)
        return $currentMemory -gt $this.MemoryThresholdBytes
    }

    # ENHANCEMENT: Emit telemetry event
    hidden [void] EmitTelemetry([string]$eventName, [hashtable]$data) {
        if (-not $this.EnableTelemetry -or $null -eq $this.OnTelemetryEvent) { return }

        try {
            $telemetryEvent = @{
                EventName = $eventName
                Timestamp = [DateTime]::Now
                Data = $data
                Source = "ExecutiveSummaryGenerator"
            }
            & $this.OnTelemetryEvent $telemetryEvent
        }
        catch {
            # Silently fail telemetry to not impact main operations
            Write-Verbose "Telemetry emission failed: $($_.Exception.Message)"
        }
    }

    # ENHANCEMENT: Validate configuration
    [bool] ValidateConfiguration([ref]$validationErrors) {
        $errors = [List[string]]::new()

        try {
            if ([string]::IsNullOrWhiteSpace($this.Config.Title)) {
                $errors.Add("Title cannot be empty")
            }

            if ($this.CacheSize -lt 1 -or $this.CacheSize -gt 10000) {
                $errors.Add("CacheSize must be between 1 and 10000")
            }

            if ($this.CacheTTLSeconds -lt 60 -or $this.CacheTTLSeconds -gt 86400) {
                $errors.Add("CacheTTLSeconds must be between 60 and 86400 (1 day)")
            }

            if ($this.ReportGenerationTimeoutMs -lt 1000 -or $this.ReportGenerationTimeoutMs -gt 300000) {
                $errors.Add("ReportGenerationTimeoutMs must be between 1000 and 300000 (5 minutes)")
            }

            # Validate color codes
            $colorPattern = '^#[0-9A-Fa-f]{6}$'
            if ($this.Config.PrimaryColor -notmatch $colorPattern) {
                $errors.Add("PrimaryColor must be a valid hex color code")
            }

            if ($this.Config.EnableLogging -and [string]::IsNullOrWhiteSpace($this.Config.LogPath)) {
                $errors.Add("LogPath must be specified when EnableLogging is true")
            }

            $validationErrors.Value = $errors.ToArray()
            return $errors.Count -eq 0
        }
        catch {
            $validationErrors.Value = @("Configuration validation failed: $($_.Exception.Message)")
            return $false
        }
    }

    # Initialize HTML templates
    hidden [void] InitializeTemplates() {
        $this.Templates['head'] = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}}</title>

    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- DataTables CSS -->
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css">

    <style>
        :root {
            --primary-color: {{PRIMARY_COLOR}};
            --success-color: {{SUCCESS_COLOR}};
            --warning-color: {{WARNING_COLOR}};
            --danger-color: {{DANGER_COLOR}};
            --info-color: {{INFO_COLOR}};
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            padding-top: 20px;
            padding-bottom: 40px;
        }

        .report-header {
            background: linear-gradient(135deg, var(--primary-color) 0%, #0a58ca 100%);
            color: white;
            padding: 40px 0;
            margin-bottom: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .metric-card {
            transition: transform 0.2s, box-shadow 0.2s;
            border: none;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }

        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.15);
        }

        .metric-value {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .metric-label {
            font-size: 0.9rem;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .health-score-widget {
            position: relative;
            width: 200px;
            height: 200px;
            margin: 0 auto;
        }

        .section-title {
            border-left: 4px solid var(--primary-color);
            padding-left: 15px;
            margin: 30px 0 20px 0;
            font-weight: 600;
        }

        .insight-card {
            background: white;
            border-left: 4px solid var(--info-color);
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .recommendation-card {
            background: white;
            border-left: 4px solid var(--warning-color);
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .pattern-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
            margin: 5px;
        }

        .severity-high {
            background-color: #fee;
            color: #d63384;
            border: 1px solid #d63384;
        }

        .severity-medium {
            background-color: #fff3cd;
            color: #997404;
            border: 1px solid #997404;
        }

        .severity-low {
            background-color: #d1e7dd;
            color: #0f5132;
            border: 1px solid #0f5132;
        }

        .chart-container {
            position: relative;
            height: 400px;
            margin: 20px 0;
        }

        .risk-matrix {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin: 20px 0;
        }

        .risk-cell {
            padding: 20px;
            text-align: center;
            border-radius: 8px;
            color: white;
            font-weight: 600;
            min-height: 100px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .risk-critical { background-color: #dc3545; }
        .risk-high { background-color: #fd7e14; }
        .risk-medium { background-color: #ffc107; color: #333; }
        .risk-low { background-color: #20c997; }

        .export-buttons {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
        }

        @media print {
            .export-buttons, .no-print { display: none; }
            body { background-color: white; }
            .metric-card { break-inside: avoid; }
        }

        .process-cluster-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .executive-summary {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }

        .timeline-item {
            border-left: 3px solid var(--primary-color);
            padding-left: 20px;
            margin-bottom: 20px;
            padding-bottom: 20px;
        }
    </style>
</head>
<body>
'@

        $this.Templates['header'] = @'
    <div class="container-fluid">
        <div class="export-buttons no-print">
            <button class="btn btn-light btn-sm me-2" onclick="window.print()">
                <i class="fas fa-print"></i> Print
            </button>
            <button class="btn btn-light btn-sm" onclick="exportToExcel()">
                <i class="fas fa-file-excel"></i> Export
            </button>
        </div>

        <div class="report-header">
            <div class="container">
                <h1 class="display-4"><i class="fas fa-chart-line me-3"></i>{{TITLE}}</h1>
                <p class="lead">{{SUBTITLE}}</p>
                <p class="mb-0"><i class="far fa-calendar-alt"></i> Generated: {{TIMESTAMP}}</p>
            </div>
        </div>
'@

        $this.Templates['footer'] = @'
    </div>

    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>

    <!-- Export Libraries -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>

    <script>
        // Initialize DataTables
        $(document).ready(function() {
            $('table.data-table').DataTable({
                pageLength: 25,
                order: [[1, 'desc']],
                responsive: true,
                dom: 'Bfrtip',
                language: {
                    search: "Filter:",
                    searchPlaceholder: "Search all columns..."
                }
            });
        });

        // Export to Excel function
        function exportToExcel() {
            const wb = XLSX.utils.book_new();

            // Export each table
            document.querySelectorAll('table.data-table').forEach((table, index) => {
                const ws = XLSX.utils.table_to_sheet(table);
                XLSX.utils.book_append_sheet(wb, ws, `Sheet${index + 1}`);
            });

            XLSX.writeFile(wb, 'ProcmonAnalysis_' + new Date().toISOString().slice(0,10) + '.xlsx');
        }

        // Smooth scroll
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        });
    </script>

    {{CHART_SCRIPTS}}
</body>
</html>
'@
    }

    # OPTIMIZATION: Generate complete HTML report with caching and lazy loading
    [string] GenerateReport([hashtable]$analytics, [hashtable]$patterns, [hashtable]$processedData) {
        # ENHANCEMENT: Check circuit breaker status
        if ($this.CircuitBreaker.IsOpen()) {
            $this.LogError("Report generation blocked - circuit breaker is OPEN", $null, @{})
            throw "Circuit breaker is open. Service temporarily unavailable."
        }

        # ENHANCEMENT: Input validation with graceful degradation
        if ($null -eq $analytics) {
            $this.LogWarning("Analytics data is null - generating minimal report")
            $analytics = @{
                Metrics = @{
                    TotalEvents = 0
                    ErrorRate = 0
                    UniqueProcesses = 0
                    UniqueOperations = 0
                    UniqueErrors = 0
                    EventsPerSecond = 0
                    AccessDeniedCount = 0
                }
                RiskAssessment = @{ Level = "Unknown"; Total = 0; ErrorScore = 0; FrequencyScore = 0; ImpactScore = 0; SecurityScore = 0; Color = "secondary" }
                HealthScore = 0
                Insights = @()
                Recommendations = @()
                Anomalies = @()
            }
        }
        if ($null -eq $patterns) {
            $this.LogWarning("Pattern data is null - skipping pattern analysis")
            $patterns = @{ DetectedPatterns = @(); ProcessClusters = @() }
        }
        if ($null -eq $processedData) {
            $this.LogWarning("Processed data is null - using default values")
            $processedData = @{ RecordCount = 0; Statistics = @{} }
        }

        # ENHANCEMENT: Timeout enforcement with cancellation
        $timeoutTimer = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            # ENHANCEMENT: Emit telemetry for report generation start
            $this.EmitTelemetry("ReportGenerationStarted", @{
                HasAnalytics = ($null -ne $analytics)
                HasPatterns = ($null -ne $patterns)
                HasProcessedData = ($null -ne $processedData)
            })

            # OPTIMIZATION: Start performance tracking
            $this.Stopwatch.Restart()

            # ENHANCEMENT: Check memory pressure before starting
            if ($this.IsMemoryPressureHigh()) {
                $this.LogWarning("High memory pressure detected - clearing expired cache entries")
                $this.CleanExpiredCache()
                [GC]::Collect()
            }

            # OPTIMIZATION: Generate cache key
            $cacheKey = $this.GenerateReportCacheKey($analytics, $patterns, $processedData)

            # OPTIMIZATION: Check cache first
            if ($this.EnableCaching -and $this.ReportCache.ContainsKey($cacheKey)) {
                $cachedReport = $this.ReportCache[$cacheKey]
                $this.Stopwatch.Stop()
                $this.LogInfo("Report cache hit - saved $([Math]::Round($this.Stopwatch.Elapsed.TotalMilliseconds, 2))ms")
                $this.CircuitBreaker.RecordSuccess()
                return $cachedReport
            }

            # ENHANCEMENT: Timeout check before proceeding
            if ($timeoutTimer.ElapsedMilliseconds -gt $this.ReportGenerationTimeoutMs) {
                throw [TimeoutException]::new("Report generation exceeded timeout of $($this.ReportGenerationTimeoutMs)ms")
            }
        }
        catch {
            $this.LogError("Error in report generation initialization", $_, @{})
            $this.CircuitBreaker.RecordFailure()
            throw
        }

        # ENHANCEMENT: Wrap report building in try-catch with graceful degradation
        try {
            $sb = [StringBuilder]::new()

            # ENHANCEMENT: Timeout check
            if ($timeoutTimer.ElapsedMilliseconds -gt $this.ReportGenerationTimeoutMs) {
                throw [TimeoutException]::new("Report generation exceeded timeout")
            }

            # Build head section with lazy loading optimizations
            $head = $this.Templates['head']
            $head = $head -replace '{{TITLE}}', $this.SanitizeString($this.Config.Title)
            $head = $head -replace '{{PRIMARY_COLOR}}', $this.Config.PrimaryColor
            $head = $head -replace '{{SUCCESS_COLOR}}', $this.Config.SuccessColor
            $head = $head -replace '{{WARNING_COLOR}}', $this.Config.WarningColor
            $head = $head -replace '{{DANGER_COLOR}}', $this.Config.DangerColor
            $head = $head -replace '{{INFO_COLOR}}', $this.Config.InfoColor
            $sb.AppendLine($head) | Out-Null

            # Build header
            $header = $this.Templates['header']
            $header = $header -replace '{{TITLE}}', $this.SanitizeString($this.Config.Title)
            $header = $header -replace '{{SUBTITLE}}', "Comprehensive System Activity Analysis"
            $header = $header -replace '{{TIMESTAMP}}', (Get-Date -Format "MMMM dd, yyyy HH:mm:ss")
            $sb.AppendLine($header) | Out-Null

            # ENHANCEMENT: Timeout check before rendering sections
            if ($timeoutTimer.ElapsedMilliseconds -gt $this.ReportGenerationTimeoutMs) {
                throw [TimeoutException]::new("Report generation exceeded timeout before rendering sections")
            }

            # OPTIMIZATION: Progressive rendering with lazy loading and graceful degradation
            try {
                $this.AddProgressiveSections($sb, $analytics, $patterns, $processedData)
            }
            catch {
                $this.LogError("Error rendering sections - using fallback content", $_, @{})
                $sb.AppendLine('<div class="container mt-4"><div class="alert alert-warning">Some report sections could not be generated. Displaying available data.</div></div>') | Out-Null
            }

            # Build footer with optimized chart scripts
            try {
                $chartScripts = $this.GenerateChartScriptsOptimized($analytics, $processedData)
                $footer = $this.Templates['footer'] -replace '{{CHART_SCRIPTS}}', $chartScripts
                $sb.AppendLine($footer) | Out-Null
            }
            catch {
                $this.LogError("Error generating chart scripts - using basic footer", $_, @{})
                $footer = $this.Templates['footer'] -replace '{{CHART_SCRIPTS}}', '<script>console.log("Charts could not be loaded");</script>'
                $sb.AppendLine($footer) | Out-Null
            }

            $result = $sb.ToString()

            # OPTIMIZATION: Cache the complete report with TTL
            if ($this.EnableCaching -and $this.ReportCache.Count -lt $this.CacheSize) {
                $this.ReportCache[$cacheKey] = $result
                $cacheEntry = [CacheEntry]::new($result, $this.CacheTTLSeconds)
                $this.ReportCacheTTL[$cacheKey] = $cacheEntry
            }

            $timeoutTimer.Stop()
            $this.Stopwatch.Stop()

            $duration = $this.Stopwatch.Elapsed.TotalMilliseconds
            $this.RecordMetric("ReportGeneration", $duration)
            $this.LogInfo("Report generation completed in $([Math]::Round($duration, 2))ms")

            # ENHANCEMENT: Record success in circuit breaker
            $this.CircuitBreaker.RecordSuccess()

            # ENHANCEMENT: Emit telemetry for completion
            $this.EmitTelemetry("ReportGenerationCompleted", @{
                DurationMs = $duration
                CacheHit = $false
                ReportSize = $result.Length
            })

            return $result
        }
        catch [TimeoutException] {
            $this.LogError("Report generation timed out after $($this.ReportGenerationTimeoutMs)ms", $_, @{})
            $this.CircuitBreaker.RecordFailure()

            # ENHANCEMENT: Return minimal report on timeout
            return $this.GenerateMinimalReport($analytics, "Report generation timed out. Showing available summary data.")
        }
        catch {
            $this.LogError("Error during report generation", $_, @{})
            $this.CircuitBreaker.RecordFailure()

            # ENHANCEMENT: Return minimal report on error
            return $this.GenerateMinimalReport($analytics, "An error occurred during report generation. Showing available summary data.")
        }
    }

    # ENHANCEMENT: Generate minimal fallback report for graceful degradation
    hidden [string] GenerateMinimalReport([hashtable]$analytics, [string]$message) {
        $sb = [StringBuilder]::new()

        try {
            # Basic HTML structure
            $sb.AppendLine('<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Analysis Report (Minimal)</title>') | Out-Null
            $sb.AppendLine('<style>body{font-family:sans-serif;margin:40px;} .alert{padding:20px;background:#fff3cd;border:1px solid #ffc107;border-radius:5px;}</style>') | Out-Null
            $sb.AppendLine('</head><body>') | Out-Null

            $sb.AppendLine("<h1>$($this.Config.Title)</h1>") | Out-Null
            $sb.AppendLine("<p><em>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</em></p>") | Out-Null
            $sb.AppendLine("<div class='alert'><strong>Notice:</strong> $message</div>") | Out-Null

            # Try to show basic metrics if available
            if ($analytics -and $analytics.Metrics) {
                $sb.AppendLine('<h2>Basic Metrics</h2><ul>') | Out-Null
                $sb.AppendLine("<li>Total Events: $($analytics.Metrics.TotalEvents)</li>") | Out-Null
                $sb.AppendLine("<li>Error Rate: $([Math]::Round($analytics.Metrics.ErrorRate * 100, 2))%</li>") | Out-Null
                $sb.AppendLine("<li>Unique Processes: $($analytics.Metrics.UniqueProcesses)</li>") | Out-Null
                $sb.AppendLine('</ul>') | Out-Null
            }

            $sb.AppendLine('</body></html>') | Out-Null

            return $sb.ToString()
        }
        catch {
            # Ultimate fallback
            return "<!DOCTYPE html><html><head><title>Error</title></head><body><h1>Report Generation Failed</h1><p>Unable to generate report. Please check logs for details.</p></body></html>"
        }
    }

    # Generate Executive Summary with configurable depth and mode
    hidden [string] GenerateExecutiveSummary([hashtable]$analytics, [hashtable]$patterns) {
        $summary = New-Object StringBuilder

        # Add mode badge
        $modeIcon = if ($this.Config.SummaryMode -eq "Executive") { "briefcase" } else { "cogs" }
        $depthBadge = switch ($this.Config.SummaryDepth) {
            "Brief" { '<span class="badge bg-info">Brief Summary</span>' }
            "Detailed" { '<span class="badge bg-primary">Detailed Analysis</span>' }
            default { '<span class="badge bg-secondary">Standard Summary</span>' }
        }

        $summary.AppendLine('<div class="container"><div class="executive-summary">') | Out-Null
        $summary.AppendLine("<h2 class='section-title'><i class='fas fa-$modeIcon me-2'></i>$($this.Config.SummaryMode) Summary $depthBadge</h2>") | Out-Null

        # Extract metrics
        $totalEvents = if ($analytics.Metrics.TotalEvents) { $analytics.Metrics.TotalEvents } else { 0 }
        $errorRate = if ($analytics.Metrics.ErrorRate) { [Math]::Round($analytics.Metrics.ErrorRate * 100, 2) } else { 0 }
        $healthScore = if ($analytics.HealthScore) { [Math]::Round($analytics.HealthScore, 1) } else { 0 }
        $riskLevel = if ($analytics.RiskAssessment.Level) { $analytics.RiskAssessment.Level } else { "Unknown" }

        # Generate summary based on depth and mode
        switch ($this.Config.SummaryDepth) {
            "Brief" {
                $summary.AppendLine($this.GenerateBriefSummary($totalEvents, $errorRate, $healthScore, $riskLevel, $analytics, $patterns)) | Out-Null
            }
            "Detailed" {
                $summary.AppendLine($this.GenerateDetailedSummary($totalEvents, $errorRate, $healthScore, $riskLevel, $analytics, $patterns)) | Out-Null
            }
            default {
                $summary.AppendLine($this.GenerateStandardSummary($totalEvents, $errorRate, $healthScore, $riskLevel, $analytics, $patterns)) | Out-Null
            }
        }

        $summary.AppendLine('</div></div>') | Out-Null
        return $summary.ToString()
    }

    # Generate Brief Summary (Executive overview only)
    hidden [string] GenerateBriefSummary([int]$totalEvents, [double]$errorRate, [double]$healthScore, [string]$riskLevel, [hashtable]$analytics, [hashtable]$patterns) {
        $content = New-Object StringBuilder

        if ($this.Config.SummaryMode -eq "Executive") {
            # Executive Brief: Business-focused, high-level
            $content.AppendLine("<p class='lead'><strong>System Status:</strong> ") | Out-Null

            $healthStatus = if ($healthScore -ge 80) { "performing excellently" }
                           elseif ($healthScore -ge 60) { "operating normally" }
                           elseif ($healthScore -ge 40) { "experiencing issues" }
                           else { "requires immediate attention" }

            $content.AppendLine("The monitored system is <strong>$healthStatus</strong> with a health score of <strong>$healthScore/100</strong>. ") | Out-Null

            if ($riskLevel -in @("Critical", "High")) {
                $content.AppendLine("<span class='text-danger'>Risk level is <strong>$riskLevel</strong> - immediate action recommended.</span>") | Out-Null
            }
            else {
                $content.AppendLine("Risk level: <strong>$riskLevel</strong>.") | Out-Null
            }
            $content.AppendLine("</p>") | Out-Null

            # Quick stats
            $content.AppendLine("<p><strong>Key Metrics:</strong> $($totalEvents.ToString('N0')) events analyzed, ") | Out-Null
            $content.AppendLine("$errorRate% error rate, ") | Out-Null
            $content.AppendLine("$($analytics.Metrics.UniqueProcesses) active processes.</p>") | Out-Null
        }
        else {
            # Technical Brief:  Technical overview
            $content.AppendLine("<p class='lead'><strong>Analysis Summary:</strong> ") | Out-Null
            $content.AppendLine("Processed <strong>$($totalEvents.ToString('N0'))</strong> system events. ") | Out-Null
            $content.AppendLine("Health Score: <strong>$healthScore/100</strong>, ") | Out-Null
            $content.AppendLine("Error Rate: <strong>$errorRate%</strong>, ") | Out-Null
            $content.AppendLine("Risk Classification: <strong>$riskLevel</strong>.") | Out-Null
            $content.AppendLine("</p>") | Out-Null

            # Technical stats
            $content.AppendLine("<p><strong>System Metrics:</strong></p><ul>") | Out-Null
            $content.AppendLine("<li>Unique Processes: $($analytics.Metrics.UniqueProcesses)</li>") | Out-Null
            $content.AppendLine("<li>Operation Types: $($analytics.Metrics.UniqueOperations)</li>") | Out-Null
            $content.AppendLine("<li>Error Conditions: $($analytics.Metrics.UniqueErrors)</li>") | Out-Null
            if ($analytics.Anomalies.Count -gt 0) {
                $content.AppendLine("<li class='text-danger'>Anomalies Detected: $($analytics.Anomalies.Count)</li>") | Out-Null
            }
            $content.AppendLine("</ul>") | Out-Null
        }

        return $content.ToString()
    }

    # Generate Standard Summary (Key findings + context)
    hidden [string] GenerateStandardSummary([int]$totalEvents, [double]$errorRate, [double]$healthScore, [string]$riskLevel, [hashtable]$analytics, [hashtable]$patterns) {
        $content = New-Object StringBuilder

        $content.AppendLine("<p class='lead'>This report analyzes <strong>$($totalEvents.ToString('N0'))</strong> system events captured during the monitoring period.</p>") | Out-Null

        # System health assessment
        $healthStatus = if ($healthScore -ge 80) { "excellent" }
                       elseif ($healthScore -ge 60) { "good" }
                       elseif ($healthScore -ge 40) { "fair" }
                       else { "poor" }

        $content.AppendLine("<h5>System Health Assessment</h5>") | Out-Null

        if ($this.Config.SummaryMode -eq "Executive") {
            $content.AppendLine("<p>The system demonstrates <strong>$healthStatus</strong> overall health with a score of <strong>$healthScore/100</strong>. ") | Out-Null

            if ($errorRate -gt 10) {
                $content.AppendLine("The elevated error rate of <strong>$errorRate%</strong> indicates significant operational issues requiring immediate attention.") | Out-Null
            }
            elseif ($errorRate -gt 5) {
                $content.AppendLine("The error rate of <strong>$errorRate%</strong> suggests moderate operational challenges that should be addressed.") | Out-Null
            }
            else {
                $content.AppendLine("The low error rate of <strong>$errorRate%</strong> indicates stable system operations.") | Out-Null
            }
            $content.AppendLine("</p>") | Out-Null
        }
        else {
            $content.AppendLine("<p>System health evaluated at <strong>$healthScore/100</strong> based on multiple metrics. ") | Out-Null
            $content.AppendLine("Current error rate: <strong>$errorRate%</strong>. ") | Out-Null
            $content.AppendLine("Events per second: <strong>$($analytics.Metrics.EventsPerSecond)</strong>. ") | Out-Null
            $content.AppendLine("</p>") | Out-Null
        }

        # Risk assessment
        $content.AppendLine("<h5>Risk Profile</h5>") | Out-Null
        $content.AppendLine("<p>The overall risk level is classified as <strong class='text-$($this.GetRiskColorClass($riskLevel))'>$riskLevel</strong>. ") | Out-Null

        if ($riskLevel -in @("Critical", "High")) {
            if ($this.Config.SummaryMode -eq "Executive") {
                $content.AppendLine("This elevated risk profile demands immediate investigation and remediation to prevent potential system instability or security breaches.") | Out-Null
            }
            else {
                $errorScore = [Math]::Round($analytics.RiskAssessment.ErrorScore, 1)
                $freqScore = [Math]::Round($analytics.RiskAssessment.FrequencyScore, 1)
                $impactScore = [Math]::Round($analytics.RiskAssessment.ImpactScore, 1)
                $content.AppendLine("Risk score breakdown: Error Impact ($errorScore), Frequency ($freqScore), System Impact ($impactScore).") | Out-Null
            }
        }
        else {
            $content.AppendLine("The current risk profile is within acceptable parameters for normal operations.") | Out-Null
        }
        $content.AppendLine("</p>") | Out-Null

        # Key findings
        $content.AppendLine("<h5>Key Findings</h5><ul>") | Out-Null
        $content.AppendLine("<li>Monitored <strong>$($analytics.Metrics.UniqueProcesses)</strong> unique processes across the system</li>") | Out-Null
        $content.AppendLine("<li>Recorded <strong>$($analytics.Metrics.UniqueOperations)</strong> distinct operation types</li>") | Out-Null

        if ($this.Config.SummaryMode -eq "Technical") {
            $content.AppendLine("<li>Identified <strong>$($analytics.Metrics.UniqueErrors)</strong> unique error conditions</li>") | Out-Null
        }

        if ($analytics.Metrics.AccessDeniedCount -gt 100) {
            $content.AppendLine("<li class='text-warning'><strong>$($analytics.Metrics.AccessDeniedCount)</strong> access denied events detected - potential security or permission issues</li>") | Out-Null
        }
        if ($analytics.Anomalies.Count -gt 0) {
            $content.AppendLine("<li class='text-danger'><strong>$($analytics.Anomalies.Count)</strong> anomalous process behaviors identified</li>") | Out-Null
        }
        $content.AppendLine("</ul>") | Out-Null

        return $content.ToString()
    }

    # Generate Detailed Summary (Comprehensive analysis)
    hidden [string] GenerateDetailedSummary([int]$totalEvents, [double]$errorRate, [double]$healthScore, [string]$riskLevel, [hashtable]$analytics, [hashtable]$patterns) {
        $content = New-Object StringBuilder

        # Introduction
        $content.AppendLine("<p class='lead'>This comprehensive analysis examines <strong>$($totalEvents.ToString('N0'))</strong> system events captured over the monitoring period, ") | Out-Null
        $content.AppendLine("providing deep insights into system behavior, patterns, and potential issues.</p>") | Out-Null

        # Detailed health assessment
        $healthStatus = if ($healthScore -ge 80) { "excellent" }
                       elseif ($healthScore -ge 60) { "good" }
                       elseif ($healthScore -ge 40) { "fair" }
                       else { "poor" }

        $content.AppendLine("<h5>Comprehensive System Health Assessment</h5>") | Out-Null
        $content.AppendLine("<p>The system demonstrates <strong>$healthStatus</strong> overall health with a composite score of <strong>$healthScore/100</strong>. ") | Out-Null
        $content.AppendLine("This score is derived from multiple weighted factors including error rates, frequency patterns, system impact metrics, and security indicators.</p>") | Out-Null

        # Error analysis
        $content.AppendLine("<h6>Error Analysis</h6>") | Out-Null
        $content.AppendLine("<p>The system recorded an error rate of <strong>$errorRate%</strong> ") | Out-Null

        if ($errorRate -gt 10) {
            $content.AppendLine("which is significantly elevated and indicates critical operational issues requiring immediate attention. ") | Out-Null
            $content.AppendLine("Root cause analysis should be initiated to identify and resolve underlying problems.") | Out-Null
        }
        elseif ($errorRate -gt 5) {
            $content.AppendLine("which suggests moderate operational challenges. ") | Out-Null
            $content.AppendLine("While not critical, these errors should be investigated to prevent escalation.") | Out-Null
        }
        else {
            $content.AppendLine("which falls within normal operational parameters and indicates stable system performance.") | Out-Null
        }
        $content.AppendLine("</p>") | Out-Null

        # Detailed risk assessment
        $content.AppendLine("<h5>Detailed Risk Profile</h5>") | Out-Null
        $content.AppendLine("<p>The comprehensive risk assessment classifies the system at <strong class='text-$($this.GetRiskColorClass($riskLevel))'>$riskLevel</strong> risk level, ") | Out-Null
        $content.AppendLine("with a composite risk score of <strong>$($analytics.RiskAssessment.Total)/100</strong>.</p>") | Out-Null

        $content.AppendLine("<h6>Risk Component Breakdown:</h6><ul>") | Out-Null
        $content.AppendLine("<li><strong>Error Impact (40% weight):</strong> $([Math]::Round($analytics.RiskAssessment.ErrorScore, 1)) - Measures the severity and frequency of system errors</li>") | Out-Null
        $content.AppendLine("<li><strong>Frequency Score (30% weight):</strong> $([Math]::Round($analytics.RiskAssessment.FrequencyScore, 1)) - Evaluates the rate of events and potential system overload</li>") | Out-Null
        $content.AppendLine("<li><strong>System Impact (20% weight):</strong> $([Math]::Round($analytics.RiskAssessment.ImpactScore, 1)) - Assesses the breadth of system resources affected</li>") | Out-Null
        $content.AppendLine("<li><strong>Security Score (10% weight):</strong> $([Math]::Round($analytics.RiskAssessment.SecurityScore, 1)) - Identifies potential security concerns and access violations</li>") | Out-Null
        $content.AppendLine("</ul>") | Out-Null

        if ($riskLevel -in @("Critical", "High")) {
            $content.AppendLine("<div class='alert alert-danger'>") | Out-Null
            $content.AppendLine("<strong>Action Required:</strong> This elevated risk profile demands immediate investigation and remediation. ") | Out-Null
            $content.AppendLine("Failure to address these issues may result in system instability, data loss, or security breaches.") | Out-Null
            $content.AppendLine("</div>") | Out-Null
        }

        # Pattern insights
        if ($patterns -and $patterns.DetectedPatterns.Count -gt 0) {
            $content.AppendLine("<h5>Advanced Pattern Recognition Insights</h5>") | Out-Null
            $content.AppendLine("<p>Machine learning algorithms identified <strong>$($patterns.DetectedPatterns.Count)</strong> significant behavioral patterns through correlation analysis and clustering techniques. ") | Out-Null

            $highSeverityPatterns = ($patterns.DetectedPatterns | Where-Object { $_.Severity -eq "High" }).Count
            $mediumSeverityPatterns = ($patterns.DetectedPatterns | Where-Object { $_.Severity -eq "Medium" }).Count
            $lowSeverityPatterns = ($patterns.DetectedPatterns | Where-Object { $_.Severity -eq "Low" }).Count

            $content.AppendLine("Pattern severity distribution: ") | Out-Null
            if ($highSeverityPatterns -gt 0) {
                $content.AppendLine("<strong class='text-danger'>$highSeverityPatterns High</strong>, ") | Out-Null
            }
            if ($mediumSeverityPatterns -gt 0) {
                $content.AppendLine("<strong class='text-warning'>$mediumSeverityPatterns Medium</strong>, ") | Out-Null
            }
            if ($lowSeverityPatterns -gt 0) {
                $content.AppendLine("<strong class='text-info'>$lowSeverityPatterns Low</strong>.") | Out-Null
            }
            $content.AppendLine("</p>") | Out-Null

            if ($highSeverityPatterns -gt 0) {
                $content.AppendLine("<p class='text-danger'><strong>Critical Finding:</strong> $highSeverityPatterns high-severity patterns require immediate review and analysis.</p>") | Out-Null
            }
        }

        # Comprehensive findings
        $content.AppendLine("<h5>Comprehensive Findings</h5><ul>") | Out-Null
        $content.AppendLine("<li><strong>Process Activity:</strong> Monitored $($analytics.Metrics.UniqueProcesses) unique processes with $($analytics.Metrics.TotalEvents.ToString('N0')) total events</li>") | Out-Null
        $content.AppendLine("<li><strong>Operation Diversity:</strong> Recorded $($analytics.Metrics.UniqueOperations) distinct operation types indicating varied system activity</li>") | Out-Null
        $content.AppendLine("<li><strong>Error Conditions:</strong> Identified $($analytics.Metrics.UniqueErrors) unique error conditions requiring investigation</li>") | Out-Null
        $content.AppendLine("<li><strong>Performance Metrics:</strong> System operating at $($analytics.Metrics.EventsPerSecond) events per second average throughput</li>") | Out-Null

        if ($analytics.Metrics.AccessDeniedCount -gt 100) {
            $content.AppendLine("<li class='text-warning'><strong>Security Concern:</strong> $($analytics.Metrics.AccessDeniedCount) access denied events detected, suggesting potential security or permission configuration issues</li>") | Out-Null
        }

        if ($analytics.Anomalies.Count -gt 0) {
            $content.AppendLine("<li class='text-danger'><strong>Anomaly Detection:</strong> $($analytics.Anomalies.Count) anomalous process behaviors identified through statistical analysis</li>") | Out-Null
        }

        if ($patterns -and $patterns.ProcessClusters) {
            $content.AppendLine("<li><strong>Process Clustering:</strong> Identified $($patterns.ProcessClusters.Count) distinct process behavior clusters</li>") | Out-Null
        }

        $content.AppendLine("</ul>") | Out-Null

        # Technical recommendations section (only for Technical mode)
        if ($this.Config.SummaryMode -eq "Technical") {
            $content.AppendLine("<h5>Technical Observations</h5>") | Out-Null
            $content.AppendLine("<p>The analysis employed advanced statistical methods including Z-Score analysis, Interquartile Range (IQR) calculations, ") | Out-Null
            $content.AppendLine("and machine learning clustering algorithms to identify patterns and anomalies. ") | Out-Null
            $content.AppendLine("Data processing utilized streaming techniques to handle large datasets efficiently.</p>") | Out-Null
        }

        return $content.ToString()
    }

    # Generate Metrics Dashboard
    hidden [string] GenerateMetricsDashboard([hashtable]$analytics, [hashtable]$processedData) {
        $metrics = New-Object StringBuilder

        $metrics.AppendLine('<div class="container mt-4">') | Out-Null
        $metrics.AppendLine('<h2 class="section-title"><i class="fas fa-tachometer-alt me-2"></i>Key Performance Indicators</h2>') | Out-Null
        $metrics.AppendLine('<div class="row">') | Out-Null

        # Total Events
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-database fa-3x text-primary mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-primary">' + $analytics.Metrics.TotalEvents.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Total Events</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Error Rate
        $errorPct = [Math]::Round($analytics.Metrics.ErrorRate * 100, 2)
        $errorClass = if ($errorPct -gt 10) { "danger" } elseif ($errorPct -gt 5) { "warning" } else { "success" }
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine("<i class='fas fa-exclamation-triangle fa-3x text-$errorClass mb-3'></i>") | Out-Null
        $metrics.AppendLine("<div class='metric-value text-$errorClass'>$errorPct%</div>") | Out-Null
        $metrics.AppendLine('<div class="metric-label">Error Rate</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Unique Processes
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-cogs fa-3x text-info mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-info">' + $analytics.Metrics.UniqueProcesses.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Unique Processes</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Events Per Second
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-clock fa-3x text-warning mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-warning">' + $analytics.Metrics.EventsPerSecond.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Events/Second</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        $metrics.AppendLine('</div></div>') | Out-Null

        return $metrics.ToString()
    }

    # Generate Health Score Section
    hidden [string] GenerateHealthScoreSection([hashtable]$analytics) {
        $section = New-Object StringBuilder

        $healthScore = [Math]::Round($analytics.HealthScore, 1)
        $scoreColor = if ($healthScore -ge 80) { "success" }
                     elseif ($healthScore -ge 60) { "info" }
                     elseif ($healthScore -ge 40) { "warning" }
                     else { "danger" }

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body text-center">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-heartbeat me-2"></i>System Health Score</h2>') | Out-Null
        $section.AppendLine('<div class="row align-items-center">') | Out-Null
        $section.AppendLine('<div class="col-md-6">') | Out-Null
        $section.AppendLine('<canvas id="healthScoreGauge" width="300" height="150"></canvas>') | Out-Null
        $section.AppendLine('</div>') | Out-Null
        $section.AppendLine('<div class="col-md-6 text-start">') | Out-Null
        $section.AppendLine("<h3 class='text-$scoreColor'>$healthScore / 100</h3>") | Out-Null
        $section.AppendLine('<p class="lead">Overall system health indicator based on error rates, anomalies, and risk factors.</p>') | Out-Null
        $section.AppendLine('<div class="progress" style="height: 30px;">') | Out-Null
        $section.AppendLine("<div class='progress-bar bg-$scoreColor' role='progressbar' style='width: $healthScore%' aria-valuenow='$healthScore' aria-valuemin='0' aria-valuemax='100'>$healthScore%</div>") | Out-Null
        $section.AppendLine('</div>') | Out-Null
        $section.AppendLine('</div></div></div></div></div>') | Out-Null

        return $section.ToString()
    }

    # Generate Risk Assessment Section
    hidden [string] GenerateRiskAssessmentSection([hashtable]$analytics) {
        $section = New-Object StringBuilder
        $risk = $analytics.RiskAssessment

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-shield-alt me-2"></i>Risk Assessment</h2>') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body">') | Out-Null

        # Risk Score
        $section.AppendLine('<div class="row mb-4">') | Out-Null
        $section.AppendLine('<div class="col-md-12">') | Out-Null
        $section.AppendLine("<h4>Overall Risk Level: <span class='badge bg-$($risk.Color) fs-5'>$($risk.Level)</span></h4>") | Out-Null
        $section.AppendLine("<p>Risk Score: <strong>$($risk.Total)</strong> out of 100</p>") | Out-Null
        $section.AppendLine('</div></div>') | Out-Null

        # Risk Components
        $section.AppendLine('<div class="row">') | Out-Null

        $components = @(
            @{ Name = "Error Impact"; Score = $risk.ErrorScore; Weight = "40%" },
            @{ Name = "Frequency"; Score = $risk.FrequencyScore; Weight = "30%" },
            @{ Name = "System Impact"; Score = $risk.ImpactScore; Weight = "20%" },
            @{ Name = "Security"; Score = $risk.SecurityScore; Weight = "10%" }
        )

        foreach ($component in $components) {
            $score = [Math]::Round($component.Score, 1)
            $barColor = if ($score -ge 70) { "danger" } elseif ($score -ge 50) { "warning" } else { "success" }

            $section.AppendLine('<div class="col-md-6 mb-3">') | Out-Null
            $section.AppendLine("<h6>$($component.Name) <small class='text-muted'>(Weight: $($component.Weight))</small></h6>") | Out-Null
            $section.AppendLine('<div class="progress" style="height: 25px;">') | Out-Null
            $section.AppendLine("<div class='progress-bar bg-$barColor' role='progressbar' style='width: $score%' aria-valuenow='$score' aria-valuemin='0' aria-valuemax='100'>$score</div>") | Out-Null
            $section.AppendLine('</div></div>') | Out-Null
        }

        $section.AppendLine('</div></div></div></div>') | Out-Null

        return $section.ToString()
    }

    # Generate Pattern Analysis Section
    hidden [string] GeneratePatternAnalysisSection([hashtable]$patterns) {
        $section = New-Object StringBuilder

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-brain me-2"></i>Pattern Analysis</h2>') | Out-Null

        # Detected Patterns
        if ($patterns.DetectedPatterns -and $patterns.DetectedPatterns.Count -gt 0) {
            $section.AppendLine('<div class="card mb-3">') | Out-Null
            $section.AppendLine('<div class="card-body">') | Out-Null
            $section.AppendLine('<h5>Detected Patterns</h5>') | Out-Null

            foreach ($pattern in $patterns.DetectedPatterns) {
                $badgeClass = if ($pattern.Severity -eq "High") { "severity-high" }
                            elseif ($pattern.Severity -eq "Medium") { "severity-medium" }
                            else { "severity-low" }

                $section.AppendLine('<div class="insight-card">') | Out-Null
                $section.AppendLine("<h6>$($pattern.Type) <span class='pattern-badge $badgeClass'>$($pattern.Severity) Severity</span></h6>") | Out-Null
                $section.AppendLine("<p>$($pattern.Description)</p>") | Out-Null
                $section.AppendLine("<small class='text-muted'>Confidence: $($pattern.Confidence * 100)%</small>") | Out-Null
                $section.AppendLine('</div>') | Out-Null
            }

            $section.AppendLine('</div></div>') | Out-Null
        }

        # Process Clusters
        if ($patterns.ProcessClusters -and $patterns.ProcessClusters.Count -gt 0) {
            $section.AppendLine('<div class="card">') | Out-Null
            $section.AppendLine('<div class="card-body">') | Out-Null
            $section.AppendLine('<h5>Process Clustering Analysis</h5>') | Out-Null

            foreach ($cluster in $patterns.ProcessClusters) {
                $section.AppendLine('<div class="process-cluster-card">') | Out-Null
                $section.AppendLine("<h6><i class='fas fa-layer-group me-2'></i>$($cluster.ClusterName)</h6>") | Out-Null
                $section.AppendLine("<p><strong>Processes:</strong> $($cluster.Processes.Count)</p>") | Out-Null
                $section.AppendLine("<p><strong>Category:</strong> $($cluster.Characteristics.Category)</p>") | Out-Null
                if ($cluster.Processes.Count -le 5) {
                    $section.AppendLine("<p><small>$($cluster.Processes -join ', ')</small></p>") | Out-Null
                }
                $section.AppendLine('</div>') | Out-Null
            }

            $section.AppendLine('</div></div>') | Out-Null
        }

        $section.AppendLine('</div>') | Out-Null

        return $section.ToString()
    }

    # Generate Charts Section
    hidden [string] GenerateChartsSection([hashtable]$analytics, [hashtable]$processedData) {
        $section = New-Object StringBuilder

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-chart-bar me-2"></i>Visual Analytics</h2>') | Out-Null

        $section.AppendLine('<div class="row">') | Out-Null

        # Top Processes Chart
        $section.AppendLine('<div class="col-md-6">') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body">') | Out-Null
        $section.AppendLine('<h5>Top Processes by Activity</h5>') | Out-Null
        $section.AppendLine('<div class="chart-container">') | Out-Null
        $section.AppendLine('<canvas id="topProcessesChart"></canvas>') | Out-Null
        $section.AppendLine('</div></div></div></div>') | Out-Null

        # Top Operations Chart
        $section.AppendLine('<div class="col-md-6">') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body">') | Out-Null
        $section.AppendLine('<h5>Top Operations</h5>') | Out-Null
        $section.AppendLine('<div class="chart-container">') | Out-Null
        $section.AppendLine('<canvas id="topOperationsChart"></canvas>') | Out-Null
        $section.AppendLine('</div></div></div></div>') | Out-Null

        $section.AppendLine('</div>') | Out-Null

        # Error Distribution Chart
        $section.AppendLine('<div class="row mt-3">') | Out-Null
        $section.AppendLine('<div class="col-md-12">') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body">') | Out-Null
        $section.AppendLine('<h5>Error Distribution</h5>') | Out-Null
        $section.AppendLine('<div class="chart-container">') | Out-Null
        $section.AppendLine('<canvas id="errorDistributionChart"></canvas>') | Out-Null
        $section.AppendLine('</div></div></div></div>') | Out-Null
        $section.AppendLine('</div>') | Out-Null

        $section.AppendLine('</div>') | Out-Null

        return $section.ToString()
    }

    # Generate Detailed Tables Section
    hidden [string] GenerateDetailedTablesSection([hashtable]$analytics, [hashtable]$processedData) {
        $section = New-Object StringBuilder

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-table me-2"></i>Detailed Analysis</h2>') | Out-Null

        # Top Processes Table
        if ($analytics.Metrics.TopProcesses) {
            $section.AppendLine('<div class="card mb-3">') | Out-Null
            $section.AppendLine('<div class="card-body">') | Out-Null
            $section.AppendLine('<h5>Top Processes</h5>') | Out-Null
            $section.AppendLine('<table class="table data-table table-striped">') | Out-Null
            $section.AppendLine('<thead><tr><th>Process Name</th><th>Event Count</th></tr></thead><tbody>') | Out-Null

            foreach ($proc in $analytics.Metrics.TopProcesses) {
                $section.AppendLine("<tr><td>$($proc.Name)</td><td>$($proc.Count.ToString('N0'))</td></tr>") | Out-Null
            }

            $section.AppendLine('</tbody></table></div></div>') | Out-Null
        }

        # Top Errors Table
        if ($analytics.Metrics.TopErrors) {
            $section.AppendLine('<div class="card">') | Out-Null
            $section.AppendLine('<div class="card-body">') | Out-Null
            $section.AppendLine('<h5>Top Errors</h5>') | Out-Null
            $section.AppendLine('<table class="table data-table table-striped">') | Out-Null
            $section.AppendLine('<thead><tr><th>Error Type</th><th>Occurrences</th></tr></thead><tbody>') | Out-Null

            foreach ($err in $analytics.Metrics.TopErrors) {
                $section.AppendLine("<tr><td>$($err.Name)</td><td>$($err.Count.ToString('N0'))</td></tr>") | Out-Null
            }

            $section.AppendLine('</tbody></table></div></div>') | Out-Null
        }

        $section.AppendLine('</div>') | Out-Null

        return $section.ToString()
    }

    # Generate Insights Section
    hidden [string] GenerateInsightsSection([hashtable]$analytics) {
        $section = New-Object StringBuilder

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-lightbulb me-2"></i>AI-Powered Insights</h2>') | Out-Null

        if ($analytics.Insights -and $analytics.Insights.Count -gt 0) {
            foreach ($insight in $analytics.Insights) {
                $section.AppendLine('<div class="insight-card">') | Out-Null
                $section.AppendLine("<p><i class='fas fa-info-circle me-2'></i>$insight</p>") | Out-Null
                $section.AppendLine('</div>') | Out-Null
            }
        }
        else {
            $section.AppendLine('<div class="alert alert-info">No significant insights detected.</div>') | Out-Null
        }

        $section.AppendLine('</div>') | Out-Null

        return $section.ToString()
    }

    # Generate Recommendations Section
    hidden [string] GenerateRecommendationsSection([hashtable]$analytics) {
        $section = New-Object StringBuilder

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-tasks me-2"></i>Recommendations</h2>') | Out-Null

        if ($analytics.Recommendations -and $analytics.Recommendations.Count -gt 0) {
            $section.AppendLine('<ol class="list-group list-group-numbered">') | Out-Null

            foreach ($rec in $analytics.Recommendations) {
                $section.AppendLine('<li class="list-group-item recommendation-card">') | Out-Null
                $section.AppendLine("<i class='fas fa-arrow-right me-2'></i>$rec") | Out-Null
                $section.AppendLine('</li>') | Out-Null
            }

            $section.AppendLine('</ol>') | Out-Null
        }
        else {
            $section.AppendLine('<div class="alert alert-success">No immediate actions required.</div>') | Out-Null
        }

        $section.AppendLine('</div>') | Out-Null

        return $section.ToString()
    }

    # Generate Chart Scripts
    hidden [string] GenerateChartScripts([hashtable]$analytics, [hashtable]$processedData) {
        $scripts = New-Object StringBuilder

        $scripts.AppendLine('<script>') | Out-Null

        # Top Processes Chart
        if ($analytics.Metrics.TopProcesses) {
            $processes = $analytics.Metrics.TopProcesses | Select-Object -First 10
            $processNames = ($processes | ForEach-Object { "'$($_.Name)'" }) -join ','
            $processCounts = ($processes | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('topProcessesChart'), {
        type: 'bar',
        data: {
            labels: [$processNames],
            datasets: [{
                label: 'Event Count',
                data: [$processCounts],
                backgroundColor: 'rgba(13, 110, 253, 0.8)',
                borderColor: 'rgba(13, 110, 253, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } }
        }
    });
"@) | Out-Null
        }

        # Top Operations Chart
        if ($analytics.Metrics.TopOperations) {
            $operations = $analytics.Metrics.TopOperations | Select-Object -First 10
            $opNames = ($operations | ForEach-Object { "'$($_.Name)'" }) -join ','
            $opCounts = ($operations | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('topOperationsChart'), {
        type: 'horizontalBar',
        data: {
            labels: [$opNames],
            datasets: [{
                label: 'Count',
                data: [$opCounts],
                backgroundColor: 'rgba(13, 202, 240, 0.8)',
                borderColor: 'rgba(13, 202, 240, 1)',
                borderWidth: 1
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } }
        }
    });
"@) | Out-Null
        }

        # Error Distribution Chart
        if ($analytics.Metrics.TopErrors) {
            $errors = $analytics.Metrics.TopErrors | Select-Object -First 8
            $errorNames = ($errors | ForEach-Object { "'$($_.Name)'" }) -join ','
            $errorCounts = ($errors | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('errorDistributionChart'), {
        type: 'pie',
        data: {
            labels: [$errorNames],
            datasets: [{
                data: [$errorCounts],
                backgroundColor: [
                    'rgba(220, 53, 69, 0.8)',
                    'rgba(253, 126, 20, 0.8)',
                    'rgba(255, 193, 7, 0.8)',
                    'rgba(25, 135, 84, 0.8)',
                    'rgba(13, 202, 240, 0.8)',
                    'rgba(13, 110, 253, 0.8)',
                    'rgba(111, 66, 193, 0.8)',
                    'rgba(214, 51, 132, 0.8)'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { position: 'right' }
            }
        }
    });
"@) | Out-Null
        }

        $scripts.AppendLine('</script>') | Out-Null

        return $scripts.ToString()
    }

    # Helper method to get risk color class
    hidden [string] GetRiskColorClass([string]$riskLevel) {
        switch ($riskLevel) {
            "Critical" { return "danger" }
            "High" { return "warning" }
            "Medium" { return "info" }
            "Low" { return "success" }
            default { return "success" }
        }
        return "success"
    }

    # Save report to file
    [void] SaveReport([string]$htmlContent, [string]$filePath) {
        [IO.File]::WriteAllText($filePath, $htmlContent, [Text.Encoding]::UTF8)
        Write-Verbose "Report saved to: $filePath"
    }

    # OPTIMIZATION: Generate cache key for report generation
    hidden [string] GenerateReportCacheKey([hashtable]$analytics, [hashtable]$patterns, [hashtable]$processedData) {
        $keyComponents = @()

        # Include analytics metrics hash
        if ($analytics -and $analytics.Metrics) {
            $metrics = $analytics.Metrics
            $metricsHash = 0
            if ($metrics.TotalEvents) { $metricsHash = $metricsHash -bxor $metrics.TotalEvents }
            if ($metrics.UniqueProcesses) { $metricsHash = $metricsHash -bxor ($metrics.UniqueProcesses * 17) }
            if ($metrics.ErrorRate) { $metricsHash = $metricsHash -bxor ([Math]::Round($metrics.ErrorRate * 100)) }
            $keyComponents += "m:$metricsHash"
        }

        # Include patterns hash
        if ($patterns -and $patterns.DetectedPatterns) {
            $patternsHash = $patterns.DetectedPatterns.Count * 13
            $keyComponents += "p:$patternsHash"
        }

        # Include configuration hash
        $configHash = 0
        if ($this.Config.SummaryDepth) { $configHash = $configHash -bxor $this.Config.SummaryDepth.GetHashCode() }
        if ($this.Config.SummaryMode) { $configHash = $configHash -bxor $this.Config.SummaryMode.GetHashCode() }
        $keyComponents += "c:$configHash"

        return [string]::Join('|', $keyComponents)
    }

    # OPTIMIZATION: Progressive rendering with lazy loading
    hidden [void] AddProgressiveSections([StringBuilder]$sb, [hashtable]$analytics, [hashtable]$patterns, [hashtable]$processedData) {
        # Executive Summary Section (always load first)
        if ($this.Config.IncludeExecutiveSummary) {
            $sb.AppendLine($this.GenerateExecutiveSummary($analytics, $patterns)) | Out-Null
        }

        # Key Metrics Dashboard (critical for initial view)
        $sb.AppendLine($this.GenerateMetricsDashboard($analytics, $processedData)) | Out-Null

        # Health Score Widget (important for quick assessment)
        $sb.AppendLine($this.GenerateHealthScoreSection($analytics)) | Out-Null

        # Risk Assessment (important for decision making)
        $sb.AppendLine($this.GenerateRiskAssessmentSection($analytics)) | Out-Null

        # Pattern Analysis (can be lazy loaded if patterns exist)
        if ($patterns) {
            $sb.AppendLine($this.GeneratePatternAnalysisSection($patterns)) | Out-Null
        }

        # Charts Section (lazy load with intersection observer)
        if ($this.Config.IncludeCharts) {
            $chartSection = $this.GenerateChartsSection($analytics, $processedData)
            # OPTIMIZATION: Add lazy loading wrapper for charts
            $lazyChartSection = $chartSection -replace '<div class="container mt-4">', '<div class="container mt-4 lazy-load" data-lazy="charts">'
            $sb.AppendLine($lazyChartSection) | Out-Null
        }

        # Detailed Tables (lazy load for performance)
        if ($this.Config.IncludeDetailedTables) {
            $tableSection = $this.GenerateDetailedTablesSection($analytics, $processedData)
            # OPTIMIZATION: Add lazy loading wrapper for tables
            $lazyTableSection = $tableSection -replace '<div class="container mt-4">', '<div class="container mt-4 lazy-load" data-lazy="tables">'
            $sb.AppendLine($lazyTableSection) | Out-Null
        }

        # Insights and Recommendations (load last as they are secondary)
        $sb.AppendLine($this.GenerateInsightsSection($analytics)) | Out-Null

        if ($this.Config.IncludeRecommendations) {
            $sb.AppendLine($this.GenerateRecommendationsSection($analytics)) | Out-Null
        }
    }

    # OPTIMIZATION: Optimized chart scripts with lazy loading
    hidden [string] GenerateChartScriptsOptimized([hashtable]$analytics, [hashtable]$processedData) {
        $scripts = [StringBuilder]::new()

        $scripts.AppendLine('<script>') | Out-Null

        # OPTIMIZATION: Add lazy loading intersection observer
        $scripts.AppendLine(@'
// Lazy loading for performance optimization
const lazyLoadObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const element = entry.target;
            const lazyType = element.dataset.lazy;

            if (lazyType === 'charts') {
                loadCharts();
            } else if (lazyType === 'tables') {
                loadTables();
            }

            lazyLoadObserver.unobserve(element);
        }
    });
});

// Observe lazy load elements
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.lazy-load').forEach(el => {
        lazyLoadObserver.observe(el);
    });
});

let chartsLoaded = false;
let tablesLoaded = false;

function loadCharts() {
    if (chartsLoaded) return;
    chartsLoaded = true;
'@) | Out-Null

        # OPTIMIZATION: Cache chart data to avoid recalculation
        $chartDataKey = "chartdata_$($this.GenerateReportCacheKey($analytics, $null, $processedData))"
        if (-not $this.ChartDataCache.ContainsKey($chartDataKey)) {
            $chartData = @{
                TopProcesses = $null
                TopOperations = $null
                TopErrors = $null
            }

            if ($analytics.Metrics.TopProcesses) {
                $chartData.TopProcesses = $analytics.Metrics.TopProcesses | Select-Object -First 10
            }
            if ($analytics.Metrics.TopOperations) {
                $chartData.TopOperations = $analytics.Metrics.TopOperations | Select-Object -First 10
            }
            if ($analytics.Metrics.TopErrors) {
                $chartData.TopErrors = $analytics.Metrics.TopErrors | Select-Object -First 8
            }

            if ($this.ChartDataCache.Count -lt $this.CacheSize) {
                $this.ChartDataCache[$chartDataKey] = $chartData
            }
        } else {
            $chartData = $this.ChartDataCache[$chartDataKey]
        }

        # OPTIMIZATION: Generate chart scripts with cached data
        if ($chartData.TopProcesses) {
            $processNames = ($chartData.TopProcesses | ForEach-Object { "'$($_.Name)'" }) -join ','
            $processCounts = ($chartData.TopProcesses | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('topProcessesChart'), {
        type: 'bar',
        data: {
            labels: [$processNames],
            datasets: [{
                label: 'Event Count',
                data: [$processCounts],
                backgroundColor: 'rgba(13, 110, 253, 0.8)',
                borderColor: 'rgba(13, 110, 253, 1)',
                borderWidth: 1
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { y: { beginAtZero: true } }
        }
    });
"@) | Out-Null
        }

        if ($chartData.TopOperations) {
            $opNames = ($chartData.TopOperations | ForEach-Object { "'$($_.Name)'" }) -join ','
            $opCounts = ($chartData.TopOperations | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('topOperationsChart'), {
        type: 'horizontalBar',
        data: {
            labels: [$opNames],
            datasets: [{
                label: 'Count',
                data: [$opCounts],
                backgroundColor: 'rgba(13, 202, 240, 0.8)',
                borderColor: 'rgba(13, 202, 240, 1)',
                borderWidth: 1
            }]
        },
        options: {
            indexAxis: 'y',
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: { x: { beginAtZero: true } }
        }
    });
"@) | Out-Null
        }

        if ($chartData.TopErrors) {
            $errorNames = ($chartData.TopErrors | ForEach-Object { "'$($_.Name)'" }) -join ','
            $errorCounts = ($chartData.TopErrors | ForEach-Object { $_.Count }) -join ','

            $scripts.AppendLine(@"
    new Chart(document.getElementById('errorDistributionChart'), {
        type: 'pie',
        data: {
            labels: [$errorNames],
            datasets: [{
                data: [$errorCounts],
                backgroundColor: [
                    'rgba(220, 53, 69, 0.8)',
                    'rgba(253, 126, 20, 0.8)',
                    'rgba(255, 193, 7, 0.8)',
                    'rgba(25, 135, 84, 0.8)',
                    'rgba(13, 202, 240, 0.8)',
                    'rgba(13, 110, 253, 0.8)',
                    'rgba(111, 66, 193, 0.8)',
                    'rgba(214, 51, 132, 0.8)'
                ]
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'right' } }
        }
    });
"@) | Out-Null
        }

        $scripts.AppendLine('}') | Out-Null

        # Add loadTables function
        $scripts.AppendLine(@'

function loadTables() {
    if (tablesLoaded) return;
    tablesLoaded = true;

    // Initialize DataTables when tables section is visible
    $('table.data-table').DataTable({
        pageLength: 25,
        order: [[1, 'desc']],
        responsive: true,
        language: {
            search: "Filter:",
            searchPlaceholder: "Search all columns..."
        }
    });
}
'@) | Out-Null

        $scripts.AppendLine('</script>') | Out-Null

        return $scripts.ToString()
    }
}

#endregion

# Note: Classes and functions are automatically available when dot-sourced
# Export-ModuleMember is only for .psm1 module files, not dot-sourced scripts
