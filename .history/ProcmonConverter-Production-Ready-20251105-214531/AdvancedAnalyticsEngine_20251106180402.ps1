#Requires -Version 5.1

<#
.SYNOPSIS
    Advanced Analytics Engine with ML/AI Capabilities

.DESCRIPTION
    Core analytics engine providing statistical analysis, anomaly detection,
    risk scoring, and performance metrics for Procmon data analysis.

.NOTES
    Version: 1.0
    Author: Enhanced Analysis Suite

.EXAMPLE
    $engine = [AdvancedAnalyticsEngine]::new()
    $analytics = $engine.AnalyzeData($processedData)
    $score = $engine.CalculateHealthScore($analytics)
#>

using namespace System.Collections.Generic
using namespace System

#region Analytics Classes

class AnalyticsResult {
    [hashtable]$Statistics
    [hashtable]$Metrics
    [hashtable]$Anomalies
    [hashtable]$RiskAssessment
    [double]$HealthScore
    [string[]]$Insights
    [string[]]$Recommendations

    AnalyticsResult() {
        $this.Statistics = @{}
        $this.Metrics = @{}
        $this.Anomalies = @{}
        $this.RiskAssessment = @{}
        $this.HealthScore = 0
        $this.Insights = @()
        $this.Recommendations = @()
    }
}

class StatisticalAnalyzer {
    # Calculate mean
    [double] CalculateMean([array]$values) {
        if ($values.Count -eq 0) { return 0 }
        $sum = 0
        foreach ($val in $values) { $sum += $val }
        return $sum / $values.Count
    }

    # Calculate standard deviation
    [double] CalculateStdDev([array]$values) {
        if ($values.Count -lt 2) { return 0 }
        $mean = $this.CalculateMean($values)
        $sumSquares = 0
        foreach ($val in $values) {
            $diff = $val - $mean
            $sumSquares += $diff * $diff
        }
        return [Math]::Sqrt($sumSquares / $values.Count)
    }

    # Calculate Z-Score
    [double] CalculateZScore([double]$value, [double]$mean, [double]$stdDev) {
        if ($stdDev -eq 0) { return 0 }
        return ($value - $mean) / $stdDev
    }

    # Calculate percentile
    [double] CalculatePercentile([array]$values, [double]$percentile) {
        if ($values.Count -eq 0) { return 0 }
        $sorted = $values | Sort-Object
        $index = [Math]::Ceiling(($percentile / 100) * $sorted.Count) - 1
        if ($index -lt 0) { $index = 0 }
        return $sorted[$index]
    }

    # Detect anomalies using Z-Score
    [hashtable] DetectAnomalies([hashtable]$data, [double]$threshold = 3.0) {
        $anomalies = @{
            Count = 0
            Items = @()
        }

        if (-not $data -or $data.Count -eq 0) { return $anomalies }

        $values = @($data.Values)
        $mean = $this.CalculateMean($values)
        $stdDev = $this.CalculateStdDev($values)

        foreach ($key in $data.Keys) {
            $zScore = $this.CalculateZScore($data[$key], $mean, $stdDev)
            if ([Math]::Abs($zScore) -gt $threshold) {
                $anomalies.Items += @{
                    Key = $key
                    Value = $data[$key]
                    ZScore = [Math]::Round($zScore, 2)
                    Severity = if ([Math]::Abs($zScore) -gt 4) { "Critical" }
                              elseif ([Math]::Abs($zScore) -gt 3) { "High" }
                              else { "Medium" }
                }
                $anomalies.Count++
            }
        }

        return $anomalies
    }
}

class RiskScoringEngine {
    [double]$ErrorWeightFactor = 0.4
    [double]$FrequencyWeightFactor = 0.3
    [double]$ImpactWeightFactor = 0.2
    [double]$SecurityWeightFactor = 0.1

    # Calculate risk score (0-100)
    [hashtable] CalculateRiskScore([hashtable]$statistics) {
        $riskScore = @{
            Total = 0
            ErrorScore = 0
            FrequencyScore = 0
            ImpactScore = 0
            SecurityScore = 0
            Level = "Low"
            Color = "success"
        }

        # Error rate score
        if ($statistics.ContainsKey('ErrorRate')) {
            $riskScore.ErrorScore = [Math]::Min(100, $statistics.ErrorRate * 100)
        }

        # Frequency score
        if ($statistics.ContainsKey('EventsPerSecond')) {
            $riskScore.FrequencyScore = [Math]::Min(100, ($statistics.EventsPerSecond / 1000) * 100)
        }

        # Impact score
        if ($statistics.ContainsKey('UniqueErrors')) {
            $riskScore.ImpactScore = [Math]::Min(100, ($statistics.UniqueErrors / 10) * 100)
        }

        # Security score
        if ($statistics.ContainsKey('AccessDeniedCount')) {
            $riskScore.SecurityScore = [Math]::Min(100, ($statistics.AccessDeniedCount / 100) * 100)
        }

        # Calculate total weighted score
        $riskScore.Total = [Math]::Round(
            ($riskScore.ErrorScore * $this.ErrorWeightFactor) +
            ($riskScore.FrequencyScore * $this.FrequencyWeightFactor) +
            ($riskScore.ImpactScore * $this.ImpactWeightFactor) +
            ($riskScore.SecurityScore * $this.SecurityWeightFactor),
            2
        )

        # Determine risk level
        if ($riskScore.Total -ge 70) {
            $riskScore.Level = "Critical"
            $riskScore.Color = "danger"
        }
        elseif ($riskScore.Total -ge 50) {
            $riskScore.Level = "High"
            $riskScore.Color = "warning"
        }
        elseif ($riskScore.Total -ge 30) {
            $riskScore.Level = "Medium"
            $riskScore.Color = "info"
        }
        else {
            $riskScore.Level = "Low"
            $riskScore.Color = "success"
        }

        return $riskScore
    }
}

class PerformanceMetricsCalculator {
    # Calculate comprehensive metrics
    [hashtable] CalculateMetrics([hashtable]$processedData) {
        $metrics = @{
            TotalEvents = 0
            ErrorRate = 0
            SuccessRate = 0
            UniqueProcesses = 0
            UniqueOperations = 0
            UniqueErrors = 0
            EventsPerSecond = 0
            AccessDeniedCount = 0
            TopProcesses = @()
            TopErrors = @()
            TopOperations = @()
        }

        if (-not $processedData) { return $metrics }

        # Total events
        if ($processedData.ContainsKey('RecordCount')) {
            $metrics.TotalEvents = $processedData.RecordCount
        }

        # Calculate rates
        if ($processedData.ContainsKey('Statistics')) {
            $stats = $processedData.Statistics

            if ($stats.Results) {
                $totalResults = 0
                $errorsCount = 0

                foreach ($key in $stats.Results.Keys) {
                    $count = $stats.Results[$key]
                    $totalResults += $count

                    if ($key -notmatch 'SUCCESS|BUFFER|FAST IO') {
                        $errorsCount += $count
                        $metrics.UniqueErrors++
                    }
                }

                if ($totalResults -gt 0) {
                    $metrics.ErrorRate = [Math]::Round(($errorsCount / $totalResults), 4)
                    $metrics.SuccessRate = [Math]::Round((1 - $metrics.ErrorRate), 4)
                }
            }

            if ($stats.ProcessTypes) {
                $metrics.UniqueProcesses = $stats.ProcessTypes.Count
                $metrics.TopProcesses = $stats.ProcessTypes.GetEnumerator() |
                    Sort-Object Value -Descending |
                    Select-Object -First 10 |
                    ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
            }

            if ($stats.Operations) {
                $metrics.UniqueOperations = $stats.Operations.Count
                $metrics.TopOperations = $stats.Operations.GetEnumerator() |
                    Sort-Object Value -Descending |
                    Select-Object -First 10 |
                    ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
            }

            if ($stats.Results) {
                $metrics.TopErrors = $stats.Results.GetEnumerator() |
                    Where-Object { $_.Key -notmatch 'SUCCESS|BUFFER|FAST IO' } |
                    Sort-Object Value -Descending |
                    Select-Object -First 10 |
                    ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
            }
        }

        # Calculate events per second
        if ($processedData.ContainsKey('Performance') -and $processedData.Performance.DurationSeconds -gt 0) {
            $metrics.EventsPerSecond = [Math]::Round($metrics.TotalEvents / $processedData.Performance.DurationSeconds, 2)
        }

        # Count access denied
        if ($processedData.ContainsKey('Statistics') -and $processedData.Statistics.Results) {
            foreach ($key in $processedData.Statistics.Results.Keys) {
                if ($key -match 'ACCESS DENIED') {
                    $metrics.AccessDeniedCount += $processedData.Statistics.Results[$key]
                }
            }
        }

        return $metrics
    }
}

#endregion

#region Advanced Analytics Engine

class AdvancedAnalyticsEngine {
    [StatisticalAnalyzer]$StatAnalyzer
    [RiskScoringEngine]$RiskEngine
    [PerformanceMetricsCalculator]$MetricsCalc

    # OPTIMIZATION: Caching and performance tracking
    [Dictionary[string,object]]$ResultCache
    [Dictionary[string,hashtable]]$MetricsCache
    [Dictionary[string,hashtable]]$AnomalyCache
    [bool]$EnableCaching = $true
    [int]$CacheSize = 5000
    [System.Diagnostics.Stopwatch]$Stopwatch

    # PERFORMANCE OPTIMIZATION: Pre-compiled regex patterns for frequently used matches
    [regex]$AccessDeniedRegex
    [regex]$SuccessRegex
    [regex]$ErrorPatternRegex

    AdvancedAnalyticsEngine() {
        $this.StatAnalyzer = [StatisticalAnalyzer]::new()
        $this.RiskEngine = [RiskScoringEngine]::new()
        $this.MetricsCalc = [PerformanceMetricsCalculator]::new()

        # OPTIMIZATION: Initialize caching
        $this.ResultCache = [Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.MetricsCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.AnomalyCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()

        # PERFORMANCE OPTIMIZATION: Pre-compile regex patterns with Compiled option
        $this.AccessDeniedRegex = [regex]::new('ACCESS DENIED', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $this.SuccessRegex = [regex]::new('SUCCESS|BUFFER|FAST IO', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $this.ErrorPatternRegex = [regex]::new('SUCCESS|BUFFER|FAST IO', [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }

    # OPTIMIZATION: Main analysis method with caching and performance improvements
    [AnalyticsResult] AnalyzeData([hashtable]$processedData) {
        # OPTIMIZATION: Start performance tracking
        $this.Stopwatch.Restart()

        # INPUT VALIDATION: Check for null or invalid input data
        if ($null -eq $processedData -or -not $processedData.ContainsKey('Statistics')) {
            Write-Warning "Invalid input data - returning empty analytics result"
            $emptyResult = [AnalyticsResult]::new()
            $emptyResult.Insights = @("No data available for analysis")
            $emptyResult.Recommendations = @("Ensure valid processed data is provided")
            $this.Stopwatch.Stop()
            return $emptyResult
        }

        # OPTIMIZATION: Generate cache key for processed data
        $cacheKey = $this.GenerateCacheKey($processedData)

        # OPTIMIZATION: Check cache first
        if ($this.EnableCaching -and $this.ResultCache.ContainsKey($cacheKey)) {
            $cachedResult = $this.ResultCache[$cacheKey]
            $this.Stopwatch.Stop()
            Write-Verbose "Cache hit for analysis result - saved $([Math]::Round($this.Stopwatch.Elapsed.TotalMilliseconds, 2))ms"
            return $cachedResult
        }

        $result = [AnalyticsResult]::new()

        # OPTIMIZATION: Calculate performance metrics with caching
        $metricsKey = "metrics_$cacheKey"
        if ($this.EnableCaching -and $this.MetricsCache.ContainsKey($metricsKey)) {
            $result.Metrics = $this.MetricsCache[$metricsKey]
        } else {
            $result.Metrics = $this.CalculateMetricsOptimized($processedData)
            if ($this.EnableCaching -and $this.MetricsCache.Count -lt $this.CacheSize) {
                $this.MetricsCache[$metricsKey] = $result.Metrics
            }
        }

        # OPTIMIZATION: Detect anomalies with caching
        if ($processedData.ContainsKey('Statistics') -and $processedData.Statistics.ProcessTypes) {
            $anomalyKey = "anomalies_$cacheKey"
            if ($this.EnableCaching -and $this.AnomalyCache.ContainsKey($anomalyKey)) {
                $result.Anomalies = $this.AnomalyCache[$anomalyKey]
            } else {
                $result.Anomalies = $this.DetectAnomaliesOptimized($processedData.Statistics.ProcessTypes)
                if ($this.EnableCaching -and $this.AnomalyCache.Count -lt $this.CacheSize) {
                    $this.AnomalyCache[$anomalyKey] = $result.Anomalies
                }
            }
        }

        # Calculate risk score
        $result.RiskAssessment = $this.RiskEngine.CalculateRiskScore($result.Metrics)

        # Calculate health score
        $result.HealthScore = $this.CalculateHealthScore($result)

        # Generate insights
        $result.Insights = $this.GenerateInsights($result)

        # Generate recommendations
        $result.Recommendations = $this.GenerateRecommendations($result)

        # Store statistics
        $result.Statistics = $processedData.Statistics

        # OPTIMIZATION: Cache the complete result
        if ($this.EnableCaching -and $this.ResultCache.Count -lt $this.CacheSize) {
            $this.ResultCache[$cacheKey] = $result
        }

        $this.Stopwatch.Stop()
        Write-Verbose "Analysis completed in $([Math]::Round($this.Stopwatch.Elapsed.TotalMilliseconds, 2))ms"

        return $result
    }

    # Calculate system health score (0-100)
    [double] CalculateHealthScore([AnalyticsResult]$analytics) {
        $healthScore = 100.0

        # Deduct for errors
        if ($analytics.Metrics.ErrorRate -gt 0) {
            $healthScore -= ($analytics.Metrics.ErrorRate * 100 * 0.4)
        }

        # Deduct for anomalies
        if ($analytics.Anomalies.Count -gt 0) {
            $healthScore -= ([Math]::Min(20, $analytics.Anomalies.Count * 2))
        }

        # Deduct for risk
        if ($analytics.RiskAssessment.Total -gt 0) {
            $healthScore -= ($analytics.RiskAssessment.Total * 0.3)
        }

        # Ensure minimum 0
        $healthScore = [Math]::Max(0, $healthScore)
        $healthScore = [Math]::Round($healthScore, 2)

        return $healthScore
    }

    # Generate insights
    [string[]] GenerateInsights([AnalyticsResult]$analytics) {
        $insights = @()

        # Error rate insight
        if ($analytics.Metrics.ErrorRate -gt 0.1) {
            $insights += "High error rate detected: $($analytics.Metrics.ErrorRate * 100)% of operations failed"
        }
        elseif ($analytics.Metrics.ErrorRate -gt 0.05) {
            $insights += "Moderate error rate: $($analytics.Metrics.ErrorRate * 100)% of operations failed"
        }
        else {
            $insights += "System performing well with low error rate: $($analytics.Metrics.ErrorRate * 100)%"
        }

        # Anomaly insight
        if ($analytics.Anomalies.Count -gt 5) {
            $insights += "$($analytics.Anomalies.Count) processes showing abnormal activity patterns"
        }
        elseif ($analytics.Anomalies.Count -gt 0) {
            $insights += "$($analytics.Anomalies.Count) process anomalies detected"
        }

        # Security insight
        if ($analytics.Metrics.AccessDeniedCount -gt 100) {
            $insights += "High number of access denied errors: $($analytics.Metrics.AccessDeniedCount) instances"
        }

        # Performance insight
        if ($analytics.Metrics.EventsPerSecond -gt 1000) {
            $insights += "High system activity: $($analytics.Metrics.EventsPerSecond) events/sec"
        }

        return $insights
    }

    # Generate recommendations
    [string[]] GenerateRecommendations([AnalyticsResult]$analytics) {
        $recommendations = @()

        # Error-based recommendations
        if ($analytics.Metrics.ErrorRate -gt 0.1) {
            $recommendations += "Investigate top error types and implement error handling"
            $recommendations += "Review application logs for root cause analysis"
        }

        # Anomaly-based recommendations
        if ($analytics.Anomalies.Count -gt 0) {
            $recommendations += "Review processes with anomalous behavior patterns"
            $recommendations += "Consider implementing process monitoring alerts"
        }

        # Security recommendations
        if ($analytics.Metrics.AccessDeniedCount -gt 50) {
            $recommendations += "Review and update file/registry permissions"
            $recommendations += "Audit user access rights and group memberships"
        }

        # Performance recommendations
        if ($analytics.Metrics.UniqueErrors -gt 20) {
            $recommendations += "Consolidate error handling for common error types"
        }

        if ($analytics.RiskAssessment.Level -in @("Critical", "High")) {
            $recommendations += "Immediate attention required: $($analytics.RiskAssessment.Level) risk level detected"
        }

        if ($recommendations.Count -eq 0) {
            $recommendations += "System health is good - continue monitoring"
        }

        return $recommendations
    }

    # OPTIMIZATION: Generate unique cache key for processed data
    [string] GenerateCacheKey([hashtable]$processedData) {
        if (-not $processedData) { return "empty" }

        $keyComponents = @()

        # Include record count
        if ($processedData.ContainsKey('RecordCount')) {
            $keyComponents += "rc:$($processedData.RecordCount)"
        }

        # Include file hash if available
        if ($processedData.ContainsKey('FileHash')) {
            $keyComponents += "fh:$($processedData.FileHash)"
        }

        # Include timestamp for uniqueness
        if ($processedData.ContainsKey('Timestamp')) {
            $keyComponents += "ts:$($processedData.Timestamp)"
        }

        # Include statistics hash
        if ($processedData.ContainsKey('Statistics')) {
            $stats = $processedData.Statistics
            $statsHash = 0

            if ($stats.ProcessTypes) {
                $statsHash = $statsHash -bxor ($stats.ProcessTypes.Count * 31)
            }
            if ($stats.Operations) {
                $statsHash = $statsHash -bxor ($stats.Operations.Count * 17)
            }
            if ($stats.Results) {
                $statsHash = $statsHash -bxor ($stats.Results.Count * 13)
            }

            $keyComponents += "sh:$statsHash"
        }

        return [string]::Join('|', $keyComponents)
    }

    # OPTIMIZATION: Optimized metrics calculation with caching
    [hashtable] CalculateMetricsOptimized([hashtable]$processedData) {
        $metrics = @{
            TotalEvents = 0
            ErrorRate = 0
            SuccessRate = 0
            UniqueProcesses = 0
            UniqueOperations = 0
            UniqueErrors = 0
            EventsPerSecond = 0
            AccessDeniedCount = 0
            TopProcesses = @()
            TopErrors = @()
            TopOperations = @()
        }

        if (-not $processedData) { return $metrics }

        # OPTIMIZATION: Use ContainsKey for hashtable compatibility
        if ($processedData.ContainsKey('RecordCount')) {
            $metrics.TotalEvents = $processedData.RecordCount
        }

        # OPTIMIZATION: Early exit for empty data
        if ($metrics.TotalEvents -eq 0) { return $metrics }

        # OPTIMIZATION: Pre-calculate statistics references
        if (-not $processedData.ContainsKey('Statistics') -or -not $processedData.Statistics) {
            return $metrics
        }

        $stats = $processedData.Statistics

        # OPTIMIZATION: Calculate rates with single pass
        if ($stats.ContainsKey('Results') -and $stats.Results) {
            $results = $stats.Results
            $totalResults = 0
            $errorsCount = 0
            $accessDeniedCount = 0

            # OPTIMIZATION: Single enumeration with conditional logic
            foreach ($key in $results.Keys) {
                $count = $results[$key]
                $totalResults += $count

                if ($key -notmatch 'SUCCESS|BUFFER|FAST IO') {
                    $errorsCount += $count
                    $metrics.UniqueErrors++
                }

                if ($key -match 'ACCESS DENIED') {
                    $accessDeniedCount += $count
                }
            }

            if ($totalResults -gt 0) {
                $metrics.ErrorRate = [Math]::Round(($errorsCount / $totalResults), 4)
                $metrics.SuccessRate = [Math]::Round((1 - $metrics.ErrorRate), 4)
            }

            $metrics.AccessDeniedCount = $accessDeniedCount

            # OPTIMIZATION: Filter and sort errors in one pass
            $metrics.TopErrors = $results.GetEnumerator() |
                Where-Object { $_.Key -notmatch 'SUCCESS|BUFFER|FAST IO' } |
                Sort-Object Value -Descending |
                Select-Object -First 10 |
                ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
        }

        # OPTIMIZATION: Process top lists efficiently
        if ($stats.ContainsKey('ProcessTypes') -and $stats.ProcessTypes) {
            $processTypes = $stats.ProcessTypes
            $metrics.UniqueProcesses = $processTypes.Count
            $metrics.TopProcesses = $processTypes.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 10 |
                ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
        }

        if ($stats.ContainsKey('Operations') -and $stats.Operations) {
            $operations = $stats.Operations
            $metrics.UniqueOperations = $operations.Count
            $metrics.TopOperations = $operations.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 10 |
                ForEach-Object { @{ Name = $_.Key; Count = $_.Value } }
        }

        # OPTIMIZATION: Calculate events per second efficiently
        if ($processedData.ContainsKey('Performance') -and $processedData.Performance) {
            $performance = $processedData.Performance
            if ($performance.ContainsKey('DurationSeconds') -and $performance.DurationSeconds -gt 0) {
                $metrics.EventsPerSecond = [Math]::Round($metrics.TotalEvents / $performance.DurationSeconds, 2)
            }
        }

        return $metrics
    }

    # OPTIMIZATION: Optimized anomaly detection with caching
    [hashtable] DetectAnomaliesOptimized([hashtable]$data) {
        $anomalies = @{
            Count = 0
            Items = @()
        }

        if (-not $data -or $data.Count -eq 0) { return $anomalies }

        # OPTIMIZATION: Pre-calculate values array for better performance
        $values = [double[]]::new($data.Count)
        $keys = [string[]]::new($data.Count)
        $i = 0

        foreach ($key in $data.Keys) {
            $keys[$i] = $key
            $values[$i] = $data[$key]
            $i++
        }

        # OPTIMIZATION: Single pass mean and variance calculation
        $mean = 0.0
        $sumSquares = 0.0
        $count = $values.Length

        for ($j = 0; $j -lt $count; $j++) {
            $mean += $values[$j]
        }
        $mean /= $count

        for ($j = 0; $j -lt $count; $j++) {
            $diff = $values[$j] - $mean
            $sumSquares += $diff * $diff
        }

        $variance = $sumSquares / $count
        $stdDev = [Math]::Sqrt($variance)

        # OPTIMIZATION: Early exit if no variance
        if ($stdDev -eq 0) { return $anomalies }

        # OPTIMIZATION: Process anomalies with threshold check
        $threshold = 3.0
        $anomalyItems = [System.Collections.Generic.List[hashtable]]::new()

        for ($j = 0; $j -lt $count; $j++) {
            $zScore = ($values[$j] - $mean) / $stdDev
            $absZScore = [Math]::Abs($zScore)

            if ($absZScore -gt $threshold) {
                $severity = if ($absZScore -gt 4) { "Critical" }
                           elseif ($absZScore -gt 3) { "High" }
                           else { "Medium" }

                $anomalyItems.Add(@{
                    Key = $keys[$j]
                    Value = $values[$j]
                    ZScore = [Math]::Round($zScore, 2)
                    Severity = $severity
                })
            }
        }

        $anomalies.Count = $anomalyItems.Count
        $anomalies.Items = $anomalyItems.ToArray()

        return $anomalies
    }
}

#endregion

# Note: Classes and functions are automatically available when dot-sourced
# Export-ModuleMember is only for .psm1 module files, not dot-sourced scripts

