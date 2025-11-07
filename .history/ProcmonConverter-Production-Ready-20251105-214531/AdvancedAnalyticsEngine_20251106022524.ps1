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

    AdvancedAnalyticsEngine() {
        $this.StatAnalyzer = [StatisticalAnalyzer]::new()
        $this.RiskEngine = [RiskScoringEngine]::new()
        $this.MetricsCalc = [PerformanceMetricsCalculator]::new()

        # OPTIMIZATION: Initialize caching
        $this.ResultCache = [Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.MetricsCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.AnomalyCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
    }

    # Main analysis method
    [AnalyticsResult] AnalyzeData([hashtable]$processedData) {
        $result = [AnalyticsResult]::new()

        # Calculate performance metrics
        $result.Metrics = $this.MetricsCalc.CalculateMetrics($processedData)

        # Detect anomalies in process activity
        if ($processedData.ContainsKey('Statistics') -and $processedData.Statistics.ProcessTypes) {
            $result.Anomalies = $this.StatAnalyzer.DetectAnomalies($processedData.Statistics.ProcessTypes)
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
}

#endregion

# Export the class
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *

