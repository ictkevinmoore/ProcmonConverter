#Requires -Version 5.1

<#
.SYNOPSIS
    Memory-Efficient Streaming CSV Processor for Large Procmon Files

.DESCRIPTION
    This module provides streaming CSV processing capabilities to handle large
    Procmon CSV files without loading them entirely into memory. It processes
    records in batches and aggregates statistics on-the-fly.

.NOTES
    Version: 1.0
    Author: Enhanced Analysis Suite

    Key Features:
    - Streaming file reading (no full file load)
    - Configurable batch processing
    - Automatic garbage collection
    - Memory-efficient statistics aggregation
    - Progress reporting support
    - Error resilience with detailed logging

.EXAMPLE
    $processor = [StreamingCSVProcessor]::new(50000, $true)
    $result = $processor.ProcessFile("large-procmon.csv")

.EXAMPLE
    # With custom statistics callback
    $processor = [StreamingCSVProcessor]::new(10000, $true)
    $processor.OnBatchProcessed = {
        param($batchNumber, $recordCount, $stats)
        Write-Host "Processed batch $batchNumber with $recordCount records"
    }
    $result = $processor.ProcessFile("procmon-data.csv")
#>

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text

#region Streaming CSV Processor Class

class StreamingCSVProcessor {
    # Configuration
    [int]$BatchSize
    [bool]$EnableGarbageCollection
    [int]$GCInterval = 50000

    # Statistics
    [Dictionary[string,int]]$ProcessTypes
    [Dictionary[string,int]]$Operations
    [Dictionary[string,int]]$Results
    [long]$TotalRecordsProcessed
    [int]$BatchesProcessed
    [DateTime]$ProcessingStartTime

    # Progress callback
    [scriptblock]$OnBatchProcessed
    [scriptblock]$OnProgress

    # Error tracking
    [List[hashtable]]$Errors
    [int]$MaxErrorsToTrack = 100

    # Performance metrics
    [hashtable]$PerformanceMetrics

    # Constructor
    StreamingCSVProcessor([int]$batchSize, [bool]$enableGC) {
        $this.BatchSize = $batchSize
        $this.EnableGarbageCollection = $enableGC
        $this.ProcessTypes = [Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Operations = [Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Results = [Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
        $this.Errors = [List[hashtable]]::new()
        $this.TotalRecordsProcessed = 0
        $this.BatchesProcessed = 0
        $this.PerformanceMetrics = @{}
    }

    # Main processing method
    [hashtable] ProcessFile([string]$filePath) {
        return $this.ProcessFile($filePath, $null)
    }

    [hashtable] ProcessFile([string]$filePath, [scriptblock]$recordFilter) {
        $this.ProcessingStartTime = [DateTime]::Now
        $reader = $null
        $recordCount = 0
        $lineNumber = 0
        $currentBatch = [List[hashtable]]::new($this.BatchSize)

        try {
            # Validate file exists
            if (-not (Test-Path $filePath)) {
                throw "File not found: $filePath"
            }

            $fileInfo = Get-Item $filePath
            $fileSizeMB = [Math]::Round($fileInfo.Length / 1MB, 2)

            Write-Verbose "Processing file: $($fileInfo.Name) ($fileSizeMB MB)"

            # Initialize streaming reader
            $reader = [StreamReader]::new($filePath, [Encoding]::UTF8, $true, 65536)

            # Read and parse header
            $headerLine = $reader.ReadLine()
            $lineNumber++

            if ([string]::IsNullOrEmpty($headerLine)) {
                throw "File is empty or has no header: $filePath"
            }

            $headers = $this.ParseCSVLine($headerLine)
            Write-Verbose "Found $($headers.Count) columns"

            # Process file line by line
            while (-not $reader.EndOfStream) {
                $line = ""
                try {
                    $line = $reader.ReadLine()
                    $lineNumber++

                    if ([string]::IsNullOrEmpty($line)) { continue }

                    # Parse line into record
                    $values = $this.ParseCSVLine($line)

                    # Create record hashtable
                    $record = @{}
                    for ($i = 0; $i -lt [Math]::Min($headers.Count, $values.Count); $i++) {
                        $record[$headers[$i]] = $values[$i]
                    }

                    # Apply filter if provided
                    if ($recordFilter) {
                        if (-not (& $recordFilter $record)) {
                            continue
                        }
                    }

                    # Add to current batch
                    $currentBatch.Add($record)
                    $recordCount++

                    # Process batch when full
                    if ($currentBatch.Count -ge $this.BatchSize) {
                        $this.ProcessBatch($currentBatch)
                        $currentBatch.Clear()

                        # Trigger GC if enabled
                        if ($this.EnableGarbageCollection -and ($recordCount % $this.GCInterval) -eq 0) {
                            $this.TriggerGarbageCollection()
                        }
                    }

                    # Report progress periodically
                    if ($this.OnProgress -and ($recordCount % 10000) -eq 0) {
                        & $this.OnProgress @{
                            RecordsProcessed = $recordCount
                            CurrentLine = $lineNumber
                            FileSizeMB = $fileSizeMB
                        }
                    }
                }
                catch {
                    $this.LogError($lineNumber, $_.Exception.Message, $line)
                }
            }

            # Process remaining records
            if ($currentBatch.Count -gt 0) {
                $this.ProcessBatch($currentBatch)
                $currentBatch.Clear()
            }

            # Calculate performance metrics
            $duration = ([DateTime]::Now - $this.ProcessingStartTime).TotalSeconds
            $this.PerformanceMetrics = @{
                DurationSeconds = [Math]::Round($duration, 2)
                RecordsPerSecond = [Math]::Round($recordCount / $duration, 0)
                FileSizeMB = $fileSizeMB
                MBPerSecond = [Math]::Round($fileSizeMB / $duration, 2)
                MemoryUsedMB = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
            }

            return @{
                Success = $true
                RecordCount = $recordCount
                LinesProcessed = $lineNumber
                Statistics = @{
                    ProcessTypes = $this.ProcessTypes
                    Operations = $this.Operations
                    Results = $this.Results
                }
                Performance = $this.PerformanceMetrics
                Errors = $this.Errors
                ErrorCount = $this.Errors.Count
            }
        }
        catch {
            return @{
                Success = $false
                Error = $_.Exception.Message
                RecordCount = $recordCount
                LinesProcessed = $lineNumber
                Statistics = @{
                    ProcessTypes = $this.ProcessTypes
                    Operations = $this.Operations
                    Results = $this.Results
                }
                Errors = $this.Errors
            }
        }
        finally {
            if ($reader) {
                $reader.Close()
                $reader.Dispose()
            }

            # Final garbage collection
            if ($this.EnableGarbageCollection) {
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            }
        }
    }

    # Parse CSV line handling quoted fields
    hidden [string[]] ParseCSVLine([string]$line) {
        $values = [List[string]]::new()
        $currentValue = [StringBuilder]::new()
        $inQuotes = $false
        $chars = $line.ToCharArray()

        for ($i = 0; $i -lt $chars.Length; $i++) {
            $char = $chars[$i]

            if ($char -eq '"') {
                # Check for escaped quote
                if ($i + 1 -lt $chars.Length -and $chars[$i + 1] -eq '"') {
                    $currentValue.Append('"')
                    $i++  # Skip next quote
                }
                else {
                    $inQuotes = -not $inQuotes
                }
            }
            elseif ($char -eq ',' -and -not $inQuotes) {
                $values.Add($currentValue.ToString())
                $currentValue.Clear()
            }
            else {
                $currentValue.Append($char)
            }
        }

        # Add final value
        $values.Add($currentValue.ToString())

        return $values.ToArray()
    }

    # Process a batch of records
    hidden [void] ProcessBatch([List[hashtable]]$batch) {
        foreach ($record in $batch) {
            $this.AggregateStatistics($record)
        }

        $this.TotalRecordsProcessed += $batch.Count
        $this.BatchesProcessed++

        # Invoke batch callback if provided
        if ($this.OnBatchProcessed) {
            & $this.OnBatchProcessed $this.BatchesProcessed $batch.Count @{
                ProcessTypes = $this.ProcessTypes.Count
                Operations = $this.Operations.Count
                Results = $this.Results.Count
            }
        }
    }

    # Aggregate statistics from a record
    hidden [void] AggregateStatistics([hashtable]$record) {
        # Process Name
        if ($record.ContainsKey('Process Name')) {
            $procName = $record['Process Name']
            if (-not [string]::IsNullOrEmpty($procName)) {
                if ($this.ProcessTypes.ContainsKey($procName)) {
                    $this.ProcessTypes[$procName]++
                } else {
                    $this.ProcessTypes[$procName] = 1
                }
            }
        }

        # Operation
        if ($record.ContainsKey('Operation')) {
            $op = $record['Operation']
            if (-not [string]::IsNullOrEmpty($op)) {
                if ($this.Operations.ContainsKey($op)) {
                    $this.Operations[$op]++
                } else {
                    $this.Operations[$op] = 1
                }
            }
        }

        # Result
        if ($record.ContainsKey('Result')) {
            $result = $record['Result']
            if (-not [string]::IsNullOrEmpty($result)) {
                if ($this.Results.ContainsKey($result)) {
                    $this.Results[$result]++
                } else {
                    $this.Results[$result] = 1
                }
            }
        }
    }

    # Trigger garbage collection
    hidden [void] TriggerGarbageCollection() {
        $before = [GC]::GetTotalMemory($false)
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        [GC]::Collect()
        $after = [GC]::GetTotalMemory($false)

        Write-Verbose "GC: Released $([Math]::Round(($before - $after) / 1MB, 2)) MB"
    }

    # Log errors
    hidden [void] LogError([int]$lineNumber, [string]$message, [string]$lineContent) {
        if ($this.Errors.Count -ge $this.MaxErrorsToTrack) {
            return  # Stop tracking to prevent memory issues
        }

        $this.Errors.Add(@{
            LineNumber = $lineNumber
            Message = $message
            Line = if ($lineContent) { $lineContent.Substring(0, [Math]::Min(100, $lineContent.Length)) } else { "" }
            Timestamp = [DateTime]::Now
        })
    }

    # Get statistics summary
    [hashtable] GetStatisticsSummary() {
        return @{
            TotalRecords = $this.TotalRecordsProcessed
            BatchesProcessed = $this.BatchesProcessed
            UniqueProcesses = $this.ProcessTypes.Count
            UniqueOperations = $this.Operations.Count
            UniqueResults = $this.Results.Count
            TopProcesses = ($this.ProcessTypes.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 10 |
                ForEach-Object { @{ Name = $_.Key; Count = $_.Value } })
            TopOperations = ($this.Operations.GetEnumerator() |
                Sort-Object Value -Descending |
                Select-Object -First 10 |
                ForEach-Object { @{ Name = $_.Key; Count = $_.Value } })
            Performance = $this.PerformanceMetrics
            ErrorCount = $this.Errors.Count
        }
    }

    # Reset statistics
    [void] Reset() {
        $this.ProcessTypes.Clear()
        $this.Operations.Clear()
        $this.Results.Clear()
        $this.Errors.Clear()
        $this.TotalRecordsProcessed = 0
        $this.BatchesProcessed = 0
        $this.PerformanceMetrics = @{}
    }
}

#endregion

#region Helper Functions

function Test-StreamingCSVProcessor {
    <#
    .SYNOPSIS
        Test the streaming CSV processor with a sample file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [int]$BatchSize = 10000
    )

    Write-Host "`n=== Streaming CSV Processor Test ===" -ForegroundColor Cyan
    Write-Host "File: $FilePath"
    Write-Host "Batch Size: $($BatchSize.ToString('N0'))`n"

    # Create processor
    $processor = [StreamingCSVProcessor]::new($BatchSize, $true)

    # Add progress callback
    $processor.OnProgress = {
        param($progressInfo)
        # Cap percentage at 100 to avoid validation errors
        # This is an estimate since we don't know total records upfront
        $estimatedTotal = $progressInfo.FileSizeMB * 10000  # Rough estimate: 10K records per MB
        $pct = if ($estimatedTotal -gt 0) {
            [Math]::Min(99, [Math]::Round(($progressInfo.RecordsProcessed / $estimatedTotal) * 100, 1))
        } else { 0 }
        Write-Progress -Activity "Processing CSV" `
            -Status "Records: $($progressInfo.RecordsProcessed.ToString('N0'))" `
            -PercentComplete $pct
    }

    # Process file
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = $processor.ProcessFile($FilePath)
    $stopwatch.Stop()

    Write-Progress -Activity "Processing CSV" -Completed

    # Display results
    Write-Host "`n=== Processing Results ===" -ForegroundColor Green
    Write-Host "Success: $($result.Success)"
    Write-Host "Records Processed: $($result.RecordCount.ToString('N0'))"
    Write-Host "Lines Processed: $($result.LinesProcessed.ToString('N0'))"
    Write-Host "Duration: $($stopwatch.Elapsed.TotalSeconds.ToString('F2')) seconds"
    Write-Host "Errors: $($result.ErrorCount)"

    if ($result.Performance) {
        Write-Host "`n=== Performance Metrics ===" -ForegroundColor Cyan
        Write-Host "Records/Second: $($result.Performance.RecordsPerSecond.ToString('N0'))"
        Write-Host "MB/Second: $($result.Performance.MBPerSecond.ToString('F2'))"
        Write-Host "Memory Used: $($result.Performance.MemoryUsedMB.ToString('F2')) MB"
    }

    if ($result.Statistics) {
        Write-Host "`n=== Statistics Summary ===" -ForegroundColor Yellow
        Write-Host "Unique Processes: $($result.Statistics.ProcessTypes.Count)"
        Write-Host "Unique Operations: $($result.Statistics.Operations.Count)"
        Write-Host "Unique Results: $($result.Statistics.Results.Count)"

        Write-Host "`nTop 5 Processes:"
        $result.Statistics.ProcessTypes.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object { Write-Host "  $($_.Key): $($_.Value.ToString('N0'))" }

        Write-Host "`nTop 5 Operations:"
        $result.Statistics.Operations.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First 5 |
            ForEach-Object { Write-Host "  $($_.Key): $($_.Value.ToString('N0'))" }
    }

    if ($result.Errors.Count -gt 0) {
        Write-Host "`n=== Errors (First 5) ===" -ForegroundColor Red
        $result.Errors | Select-Object -First 5 | ForEach-Object {
            Write-Host "  Line $($_.LineNumber): $($_.Message)"
        }
    }

    return $result
}

function Compare-ProcessingMethods {
    <#
    .SYNOPSIS
        Compare streaming vs. traditional Import-CSV performance
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [int]$BatchSize = 50000
    )

    Write-Host "`n=== Processing Method Comparison ===" -ForegroundColor Cyan
    Write-Host "File: $FilePath`n"

    $fileSize = [Math]::Round((Get-Item $FilePath).Length / 1MB, 2)
    Write-Host "File Size: $fileSize MB`n"

    # Test streaming method
    Write-Host "Testing Streaming Method..." -ForegroundColor Yellow
    $processor = [StreamingCSVProcessor]::new($BatchSize, $true)

    $streamStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $memBefore = [GC]::GetTotalMemory($true) / 1MB

    $streamResult = $processor.ProcessFile($FilePath)

    $memAfter = [GC]::GetTotalMemory($false) / 1MB
    $streamStopwatch.Stop()

    $streamMemory = $memAfter - $memBefore

    Write-Host "  Duration: $($streamStopwatch.Elapsed.TotalSeconds.ToString('F2'))s"
    Write-Host "  Memory: $($streamMemory.ToString('F2')) MB"
    Write-Host "  Records: $($streamResult.RecordCount.ToString('N0'))"

    # Test traditional method (with size limit)
    if ($fileSize -lt 100) {
        Write-Host "`nTesting Traditional Method (Import-CSV)..." -ForegroundColor Yellow

        $traditionalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $memBefore = [GC]::GetTotalMemory($true) / 1MB

        $data = Import-Csv $FilePath
        $count = $data.Count

        $memAfter = [GC]::GetTotalMemory($false) / 1MB
        $traditionalStopwatch.Stop()

        $traditionalMemory = $memAfter - $memBefore

        Write-Host "  Duration: $($traditionalStopwatch.Elapsed.TotalSeconds.ToString('F2'))s"
        Write-Host "  Memory: $($traditionalMemory.ToString('F2')) MB"
        Write-Host "  Records: $($count.ToString('N0'))"

        # Comparison
        Write-Host "`n=== Comparison ===" -ForegroundColor Green
        $speedup = $traditionalStopwatch.Elapsed.TotalSeconds / $streamStopwatch.Elapsed.TotalSeconds
        $memSavings = (($traditionalMemory - $streamMemory) / $traditionalMemory) * 100

        Write-Host "Speed: Streaming is $($speedup.ToString('F2'))x $(if($speedup -gt 1){'faster'}else{'slower'})"
        Write-Host "Memory: Streaming uses $($memSavings.ToString('F1'))% $(if($memSavings -gt 0){'less'}else{'more'}) memory"
    }
    else {
        Write-Host "`nSkipping traditional method (file too large)" -ForegroundColor Yellow
    }
}

#endregion

<#
.EXAMPLE - Basic Usage
    Import-Module .\StreamingCSVProcessor.ps1
    Test-StreamingCSVProcessor -FilePath "Data\Converted\large-file.csv"

.EXAMPLE - Custom Processing
    $processor = [StreamingCSVProcessor]::new(50000, $true)
    $processor.OnProgress = {
        param($info)
        Write-Host "Processed $($info.RecordsProcessed) records..."
    }
    $result = $processor.ProcessFile("data.csv")

.EXAMPLE - With Filtering
    $processor = [StreamingCSVProcessor]::new(10000, $true)
    $result = $processor.ProcessFile("data.csv", {
        param($record)
        # Only process records from specific process
        return $record['Process Name'] -eq 'explorer.exe'
    })

.EXAMPLE - Performance Comparison
    Import-Module .\StreamingCSVProcessor.ps1
    Compare-ProcessingMethods -FilePath "Data\Converted\sample.csv"
#>
