#Requires -Version 5.1

<#
.SYNOPSIS
    Pattern Recognition Engine for Procmon Data Analysis

.DESCRIPTION
    Provides pattern detection capabilities including process clustering,
    temporal pattern mining, error correlation, and behavior baseline establishment.

.NOTES
    Version: 1.0
    Author: Enhanced Analysis Suite

.EXAMPLE
    $engine = [PatternRecognitionEngine]::new()
    $patterns = $engine.AnalyzePatterns($processedData)
#>

using namespace System.Collections.Generic
using namespace System

#region Pattern Recognition Classes

class Pattern {
    [string]$Type
    [string]$Description
    [hashtable]$Data
    [double]$Confidence
    [string]$Severity

    Pattern([string]$type, [string]$description, [hashtable]$data, [double]$confidence) {
        $this.Type = $type
        $this.Description = $description
        $this.Data = $data
        $this.Confidence = [Math]::Round($confidence, 2)
        $this.Severity = $this.DetermineSeverity()
    }

    hidden [string] DetermineSeverity() {
        if ($this.Confidence -ge 0.8) { return "High" }
        elseif ($this.Confidence -ge 0.6) { return "Medium" }
        else { return "Low" }
    }
}

class ProcessCluster {
    [string]$ClusterName
    [string[]]$Processes
    [hashtable]$Characteristics
    [double]$ActivityScore

    ProcessCluster([string]$name) {
        $this.ClusterName = $name
        $this.Processes = @()
        $this.Characteristics = @{}
        $this.ActivityScore = 0
    }
}

class TemporalPattern {
    [string]$PatternType
    [hashtable]$TimeDistribution
    [string]$PeakHour
    [string]$TrendDirection
    [double]$Seasonality

    TemporalPattern() {
        $this.TimeDistribution = @{}
        $this.TrendDirection = "Stable"

 $this.Seasonality = 0
    }
}

class PatternRecognitionResult {
    [List[Pattern]]$DetectedPatterns
    [List[ProcessCluster]]$ProcessClusters
    [TemporalPattern]$TemporalPatterns
    [hashtable]$ErrorCorrelations
    [hashtable]$BehaviorBaseline
    [double]$OverallConfidence

    PatternRecognitionResult() {
        $this.DetectedPatterns = [List[Pattern]]::new()
        $this.ProcessClusters = [List[ProcessCluster]]::new()
        $this.TemporalPatterns = [TemporalPattern]::new()
        $this.ErrorCorrelations = @{}
        $this.BehaviorBaseline = @{}
        $this.OverallConfidence = 0
    }
}

#endregion

#region Pattern Recognition Engine

class PatternRecognitionEngine {
    # OPTIMIZATION: Caching and performance tracking
    [Dictionary[string,PatternRecognitionResult]]$ResultCache
    [Dictionary[string,List[ProcessCluster]]]$ClusterCache
    [Dictionary[string,TemporalPattern]]$TemporalCache
    [Dictionary[string,hashtable]]$CorrelationCache
    [Dictionary[string,hashtable]]$BaselineCache
    [bool]$EnableCaching = $true
    [int]$CacheSize = 5000
    [System.Diagnostics.Stopwatch]$Stopwatch

    PatternRecognitionEngine() {
        # OPTIMIZATION: Initialize caching
        $this.ResultCache = [Dictionary[string,PatternRecognitionResult]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.ClusterCache = [Dictionary[string,List[ProcessCluster]]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.TemporalCache = [Dictionary[string,TemporalPattern]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.CorrelationCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.BaselineCache = [Dictionary[string,hashtable]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Stopwatch = [System.Diagnostics.Stopwatch]::new()
    }

    # OPTIMIZATION: Analyze all patterns with caching and performance improvements
    [PatternRecognitionResult] AnalyzePatterns([hashtable]$processedData) {
        # OPTIMIZATION: Start performance tracking
        $this.Stopwatch.Restart()

        # OPTIMIZATION: Generate cache key
        $cacheKey = $this.GenerateCacheKey($processedData)

        # OPTIMIZATION: Check cache first
        if ($this.EnableCaching -and $this.ResultCache.ContainsKey($cacheKey)) {
            $cachedResult = $this.ResultCache[$cacheKey]
            $this.Stopwatch.Stop()
            Write-Verbose "Cache hit for pattern analysis - saved $([Math]::Round($this.Stopwatch.Elapsed.TotalMilliseconds, 2))ms"
            return $cachedResult
        }

        $result = [PatternRecognitionResult]::new()

        if (-not $processedData -or -not $processedData.ContainsKey('Statistics')) {
            return $result
        }

        $stats = $processedData.Statistics

        # OPTIMIZATION: Perform process clustering with caching
        $clusterKey = "clusters_$cacheKey"
        if ($this.EnableCaching -and $this.ClusterCache.ContainsKey($clusterKey)) {
            $result.ProcessClusters = $this.ClusterCache[$clusterKey]
        } else {
            $result.ProcessClusters = $this.ClusterProcessesOptimized($stats.ProcessTypes, $stats.Operations)
            if ($this.EnableCaching -and $this.ClusterCache.Count -lt $this.CacheSize) {
                $this.ClusterCache[$clusterKey] = $result.ProcessClusters
            }
        }

        # OPTIMIZATION: Analyze temporal patterns with caching
        $temporalKey = "temporal_$cacheKey"
        if ($this.EnableCaching -and $this.TemporalCache.ContainsKey($temporalKey)) {
            $result.TemporalPatterns = $this.TemporalCache[$temporalKey]
        } else {
            $result.TemporalPatterns = $this.AnalyzeTemporalPatternsOptimized($stats)
            if ($this.EnableCaching -and $this.TemporalCache.Count -lt $this.CacheSize) {
                $this.TemporalCache[$temporalKey] = $result.TemporalPatterns
            }
        }

        # OPTIMIZATION: Detect error correlations with caching
        $correlationKey = "correlations_$cacheKey"
        if ($this.EnableCaching -and $this.CorrelationCache.ContainsKey($correlationKey)) {
            $result.ErrorCorrelations = $this.CorrelationCache[$correlationKey]
        } else {
            $result.ErrorCorrelations = $this.DetectErrorCorrelationsOptimized($stats.Results, $stats.ProcessTypes)
            if ($this.EnableCaching -and $this.CorrelationCache.Count -lt $this.CacheSize) {
                $this.CorrelationCache[$correlationKey] = $result.ErrorCorrelations
            }
        }

        # OPTIMIZATION: Establish behavior baseline with caching
        $baselineKey = "baseline_$cacheKey"
        if ($this.EnableCaching -and $this.BaselineCache.ContainsKey($baselineKey)) {
            $result.BehaviorBaseline = $this.BaselineCache[$baselineKey]
        } else {
            $result.BehaviorBaseline = $this.EstablishBaselineOptimized($stats)
            if ($this.EnableCaching -and $this.BaselineCache.Count -lt $this.CacheSize) {
                $this.BaselineCache[$baselineKey] = $result.BehaviorBaseline
            }
        }

        # OPTIMIZATION: Detect specific patterns with optimized methods
        $this.DetectFrequencyPatternsOptimized($stats.ProcessTypes, $result)
        $this.DetectErrorPatternsOptimized($stats.Results, $result)
        $this.DetectSecurityPatternsOptimized($stats.Results, $result)

        # Calculate overall confidence
        $result.OverallConfidence = $this.CalculateOverallConfidence($result)

        # OPTIMIZATION: Cache complete result
        if ($this.EnableCaching -and $this.ResultCache.Count -lt $this.CacheSize) {
            $this.ResultCache[$cacheKey] = $result
        }

        $this.Stopwatch.Stop()
        Write-Verbose "Pattern analysis completed in $([Math]::Round($this.Stopwatch.Elapsed.TotalMilliseconds, 2))ms"

        return $result
    }

    # Cluster processes by behavior
    [List[ProcessCluster]] ClusterProcesses([hashtable]$processTypes, [hashtable]$operations) {
        $clusters = [List[ProcessCluster]]::new()

        if (-not $processTypes -or $processTypes.Count -eq 0) {
            return $clusters
        }

        # Simple clustering by activity level
        $highActivity = [ProcessCluster]::new("High Activity")
        $mediumActivity = [ProcessCluster]::new("Medium Activity")
        $lowActivity = [ProcessCluster]::new("Low Activity")

        # Calculate total activity
        $totalActivity = 0
        foreach ($count in $processTypes.Values) {
            $totalActivity += $count
        }
        $avgActivity = $totalActivity / $processTypes.Count

        # Classify processes
        foreach ($key in $processTypes.Keys) {
            $count = $processTypes[$key]

            if ($count -gt ($avgActivity * 2)) {
                $highActivity.Processes += $key
                $highActivity.ActivityScore += $count
            }
            elseif ($count -gt ($avgActivity * 0.5)) {
                $mediumActivity.Processes += $key
                $mediumActivity.ActivityScore += $count
            }
            else {
                $lowActivity.Processes += $key
                $lowActivity.ActivityScore += $count
            }
        }

        # Add characteristics
        $highActivity.Characteristics = @{
            AverageActivity = [Math]::Round($highActivity.ActivityScore / [Math]::Max(1, $highActivity.Processes.Count), 2)
            ProcessCount = $highActivity.Processes.Count
            Category = "System Critical"
        }

        $mediumActivity.Characteristics = @{
            AverageActivity = [Math]::Round($mediumActivity.ActivityScore / [Math]::Max(1, $mediumActivity.Processes.Count), 2)
            ProcessCount = $mediumActivity.Processes.Count
            Category = "Standard Operations"
        }

        $lowActivity.Characteristics = @{
            AverageActivity = [Math]::Round($lowActivity.ActivityScore / [Math]::Max(1, $lowActivity.Processes.Count), 2)
            ProcessCount = $lowActivity.Processes.Count
            Category = "Background Tasks"
        }

        $clusters.Add($highActivity)
        $clusters.Add($mediumActivity)
        $clusters.Add($lowActivity)

        return $clusters
    }

    # Analyze temporal patterns
    [TemporalPattern] AnalyzeTemporalPatterns([hashtable]$statistics) {
        $temporal = [TemporalPattern]::new()
        $temporal.PatternType = "Activity Distribution"

        # Simplified temporal analysis (would need actual timestamps in real implementation)
        # Using process counts as proxy for activity
        if ($statistics.ProcessTypes -and $statistics.ProcessTypes.Count -gt 0) {
            $values = @($statistics.ProcessTypes.Values)
            $sorted = $values | Sort-Object -Descending

            if ($sorted.Count -gt 0) {
                $maxActivity = $sorted[0]
                $minActivity = $sorted[-1]
                $avgActivity = ($values | Measure-Object -Average).Average

                # Determine trend
                if ($maxActivity -gt ($avgActivity * 3)) {
                    $temporal.TrendDirection = "Spiky"
                }
                elseif ($maxActivity -gt ($avgActivity * 1.5)) {
                    $temporal.TrendDirection = "Increasing"
                }
                else {
                    $temporal.TrendDirection = "Stable"
                }

                # Estimate seasonality
                $temporal.Seasonality = [Math]::Round(($maxActivity - $minActivity) / [Math]::Max(1, $avgActivity), 2)
            }
        }

        return $temporal
    }

    # Detect error correlations
    [hashtable] DetectErrorCorrelations([hashtable]$results, [hashtable]$processes) {
        $correlations = @{
            StrongCorrelations = @()
            WeakCorrelations = @()
            ErrorClusters = @()
        }

        if (-not $results -or $results.Count -eq 0) {
            return $correlations
        }

        # Find error patterns
        $errorResults = $results.GetEnumerator() | Where-Object {
            $_.Key -notmatch 'SUCCESS|BUFFER|FAST IO'
        } | Sort-Object Value -Descending

        # Group related errors
        $accessErrors = @()
        $fileErrors = @()
        $registryErrors = @()
        $otherErrors = @()

        foreach ($error in $errorResults) {
            if ($error.Key -match 'ACCESS|DENIED|PRIVILEGE') {
                $accessErrors += @{ Error = $error.Key; Count = $error.Value }
            }
            elseif ($error.Key -match 'FILE|PATH|NOT FOUND') {
                $fileErrors += @{ Error = $error.Key; Count = $error.Value }
            }
            elseif ($error.Key -match 'REGISTRY|KEY') {
                $registryErrors += @{ Error = $error.Key; Count = $error.Value }
            }
            else {
                $otherErrors += @{ Error = $error.Key; Count = $error.Value }
            }
        }

        # Add error clusters
        if ($accessErrors.Count -gt 0) {
            $correlations.ErrorClusters += @{
                Type = "Access Errors"
                Count = $accessErrors.Count
                Errors = $accessErrors
            }
        }

        if ($fileErrors.Count -gt 0) {
            $correlations.ErrorClusters += @{
                Type = "File System Errors"
                Count = $fileErrors.Count
                Errors = $fileErrors
            }
        }

        if ($registryErrors.Count -gt 0) {
            $correlations.ErrorClusters += @{
                Type = "Registry Errors"
                Count = $registryErrors.Count
                Errors = $registryErrors
            }
        }

        return $correlations
    }

    # Establish behavior baseline
    [hashtable] EstablishBaseline([hashtable]$statistics) {
       $baseline = @{
            NormalProcessCount = 0
            NormalOperationCount = 0
            BaselineErrorRate = 0
            TypicalProcesses = @()
            TypicalOperations = @()
            Thresholds = @{}
        }

        if ($statistics.ProcessTypes) {
            $baseline.NormalProcessCount = $statistics.ProcessTypes.Count
            $values = @($statistics.ProcessTypes.Values)
            if ($values.Count -gt 0) {
                $baseline.Thresholds.ProcessActivityMean = ($values | Measure-Object -Average).Average
                $baseline.Thresholds.ProcessActivityMax = ($values | Measure-Object -Maximum).Maximum
            }
            $baseline.TypicalProcesses = $statistics.ProcessTypes.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 20 |
                ForEach-Object { $_.Key }
        }

        if ($statistics.Operations) {
            $baseline.NormalOperationCount = $statistics.Operations.Count
            $baseline.TypicalOperations = $statistics.Operations.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 20 |
                ForEach-Object { $_.Key }
        }

        if ($statistics.Results) {
            $total = 0
            $errors = 0
            foreach ($key in $statistics.Results.Keys) {
                $count = $statistics.Results[$key]
                $total += $count
                if ($key -notmatch 'SUCCESS|BUFFER|FAST IO') {
                    $errors += $count
                }
            }
            if ($total -gt 0) {
                $baseline.BaselineErrorRate = [Math]::Round($errors / $total, 4)
            }
        }

        return $baseline
    }

    # Detect frequency patterns
    hidden [void] DetectFrequencyPatterns([hashtable]$processTypes, [PatternRecognitionResult]$result) {
        if (-not $processTypes -or $processTypes.Count -eq 0) { return }

        $values = @($processTypes.Values)
        $avg = ($values | Measure-Object -Average).Average

        # Detect high-frequency patterns
        foreach ($key in $processTypes.Keys) {
            if ($processTypes[$key] -gt ($avg * 5)) {
                $pattern = [Pattern]::new(
                    "High Frequency",
                    "Process '$key' shows exceptionally high activity",
                    @{ Process = $key; Count = $processTypes[$key]; Ratio = [Math]::Round($processTypes[$key] / $avg, 2) },
                    0.9
                )
                $result.DetectedPatterns.Add($pattern)
            }
        }
    }

    # Detect error patterns
    hidden [void] DetectErrorPatterns([hashtable]$results, [PatternRecognitionResult]$result) {
        if (-not $results -or $results.Count -eq 0) { return }

        foreach ($key in $results.Keys) {
            if ($key -match 'ACCESS DENIED' -and $results[$key] -gt 50) {
                $pattern = [Pattern]::new(
                    "Security Pattern",
                    "High volume of access denied errors detected",
                    @{ ErrorType = $key; Count = $results[$key] },
                    0.85
                )
                $result.DetectedPatterns.Add($pattern)
            }

            if ($key -match 'NAME NOT FOUND|PATH NOT FOUND' -and $results[$key] -gt 100) {
                $pattern = [Pattern]::new(
                    "File System Pattern",
                    "High volume of file/path not found errors",
                    @{ ErrorType = $key; Count = $results[$key] },
                    0.8
                )
                $result.DetectedPatterns.Add($pattern)
            }
        }
    }

    # Detect security patterns
   hidden [void] DetectSecurityPatterns([hashtable]$results, [PatternRecognitionResult]$result) {
        if (-not $results -or $results.Count -eq 0) { return }

        $securityKeywords = @('ACCESS', 'DENIED', 'PRIVILEGE', 'PERMISSION', 'SECURITY')
        $securityCount = 0

        foreach ($key in $results.Keys) {
            foreach ($keyword in $securityKeywords) {
                if ($key -match $keyword) {
                    $securityCount += $results[$key]
                    break
                }
            }
        }

        if ($securityCount -gt 100) {
            $pattern = [Pattern]::new(
                "Security Alert",
                "Elevated security-related errors detected across system",
                @{ TotalSecurityErrors = $securityCount },
                0.9
            )
            $result.DetectedPatterns.Add($pattern)
        }
    }

    # Calculate overall confidence score
    [double] CalculateOverallConfidence([PatternRecognitionResult]$result) {
        if ($result.DetectedPatterns.Count -eq 0) {
            return 0.5  # Neutral confidence when no patterns detected
        }

        $totalConfidence = 0
        foreach ($pattern in $result.DetectedPatterns) {
            $totalConfidence += $pattern.Confidence
        }

        return [Math]::Round($totalConfidence / $result.DetectedPatterns.Count, 2)
    }
}

#endregion

# Export the class
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *

