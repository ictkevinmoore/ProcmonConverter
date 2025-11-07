#Requires -Version 5.1

<#
.SYNOPSIS
    Memory-Efficient Streaming CSV Processor with Advanced Post-Processing

.DESCRIPTION
    This module provides streaming CSV processing capabilities with comprehensive
    post-processing features including:
    - Success result filtering (removes SUCCESS, keeps errors/warnings)
    - Duplicate detection and removal
    - Data validation and sanitization
    - Malformed entry handling
    - Automated cleanup and archival
    - Enhanced reporting and statistics

.NOTES
    Version: 2.0-PostProcessing-Enhanced
    Author: Enhanced Analysis Suite

    Key Features:
    ✅ Streaming file reading (no full file load)
    ✅ Configurable batch processing
    ✅ Success result filtering and archival
    ✅ Duplicate detection by hash
    ✅ Data sanitization and validation
    ✅ Automatic garbage collection
    ✅ Memory-efficient statistics aggregation
    ✅ Progress reporting support
    ✅ Comprehensive error handling and logging
    ✅ Post-processing cleanup pipeline

.EXAMPLE
    $processor = [StreamingCSVProcessor]::new(50000, $true)
    $result = $processor.ProcessFile("large-procmon.csv", $true) # Enable post-processing

.EXAMPLE
    # With custom post-processing options
    $options = @{
        FilterSuccessResults = $true
        RemoveDuplicates = $true
        SanitizeData = $true
        CreateArchive = $true
    }
    $processor = [StreamingCSVProcessor]::new(10000, $true)
    $result = $processor.ProcessFileWithOptions("procmon-data.csv", $options)
#>

using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Text
using namespace System.Security.Cryptography

#region CSV Post-Processor Class

class CSVPostProcessingOptions {
    [bool]$FilterSuccessResults = $true
    [bool]$RemoveDuplicates = $true
    [bool]$SanitizeData = $true
    [bool]$ValidateFields = $true
    [bool]$CreateArchive = $true
    [bool]$CreateSeparateOutputs = $true
    [string]$ArchiveDirectory = "Archive"
    [string]$CleanedOutputSuffix = "-cleaned"
    [string[]]$SuccessIndicators = @("SUCCESS", "BUFFER OVERFLOW", "FAST IO DISALLOWED")
    [string[]]$RequiredFields = @("Time of Day", "Process Name", "Operation", "Path", "Result")

    CSVPostProcessingOptions() {
        # Default constructor with default values
    }
}

class CSVPostProcessingStats {
    [int]$TotalRecordsProcessed = 0
    [int]$RecordsRetained = 0
    [int]$SuccessRecordsFiltered = 0
    [int]$DuplicatesRemoved = 0
    [int]$MalformedRecordsFixed = 0
    [int]$InvalidRecordsSkipped = 0
    [int]$DataSanitizationCount = 0
    [DateTime]$StartTime
    [DateTime]$EndTime
    [double]$DurationSeconds = 0
    [hashtable]$FilteredResultTypes = @{}

    [void] Calculate() {
        if ($this.StartTime -and $this.EndTime) {
            $this.DurationSeconds = ($this.EndTime - $this.StartTime).TotalSeconds
        }
    }

    [hashtable] ToHashtable() {
        return @{
            TotalProcessed = $this.TotalRecordsProcessed
            Retained = $this.RecordsRetained
            SuccessFiltered = $this.SuccessRecordsFiltered
            DuplicatesRemoved = $this.DuplicatesRemoved
            MalformedFixed = $this.MalformedRecordsFixed
            InvalidSkipped = $this.InvalidRecordsSkipped
            Sanitized = $this.DataSanitizationCount
            Duration = $this.DurationSeconds
            FilteredTypes = $this.FilteredResultTypes
        }
    }
}

class CSVPostProcessor {
    [CSVPostProcessingOptions]$Options
    [CSVPostProcessingStats]$Stats
    [HashSet[string]]$SeenHashes
    [StreamWriter]$CleanedWriter
    [StreamWriter]$SuccessWriter
    [List[hashtable]]$ErrorLog

    CSVPostProcessor([CSVPostProcessingOptions]$options) {
        $this.Options = $options
        $this.Stats = [CSVPostProcessingStats]::new()
        $this.Stats.StartTime = [DateTime]::Now
        $this.SeenHashes = [HashSet[string]]::new()
        $this.ErrorLog = [List[hashtable]]::new()
    }

    # Initialize output streams
    [void] InitializeOutputStreams([string]$inputPath) {
        $directory = [Path]::GetDirectoryName($inputPath)
        $fileName = [Path]::GetFileNameWithoutExtension($inputPath)
        $extension = [Path]::GetExtension($inputPath)

        if ($this.Options.CreateSeparateOutputs) {
            # Cleaned output file
            $cleanedPath = Join-Path $directory "$fileName$($this.Options.CleanedOutputSuffix)$extension"
            $this.CleanedWriter = [StreamWriter]::new($cleanedPath, $false, [Encoding]::UTF8)

            # Archive directory for success records
            if ($this.Options.CreateArchive) {
                $archivePath = Join-Path $directory $this.Options.ArchiveDirectory
                if (-not (Test-Path $archivePath)) {
                    New-Item -Path $archivePath -ItemType Directory -Force | Out-Null
                }
                $successPath = Join-Path $archivePath "$fileName-success$extension"
                $this.SuccessWriter = [StreamWriter]::new($successPath, $false, [Encoding]::UTF8)
            }
        }
    }

    # Close output streams
    [void] CloseOutputStreams() {
        if ($this.CleanedWriter) {
            $this.CleanedWriter.Flush()
            $this.CleanedWriter.Close()
            $this.CleanedWriter.Dispose()
        }
        if ($this.SuccessWriter) {
            $this.SuccessWriter.Flush()
            $this.SuccessWriter.Close()
            $this.SuccessWriter.Dispose()
        }
        $this.Stats.EndTime = [DateTime]::Now
        $this.Stats.Calculate()
    }

    # Calculate hash for duplicate detection
    hidden [string] CalculateRecordHash([hashtable]$record) {
        $hashFields = @(
            $record['Time of Day'],
            $record['Process Name'],
            $record['PID'],
            $record['Operation'],
            $record['Path']
        ) | Where-Object { $_ } | ForEach-Object { $_.ToString() }

        $hashString = $hashFields -join '|'
        $bytes = [Text.Encoding]::UTF8.GetBytes($hashString)
        $hash = [MD5]::Create().ComputeHash($bytes)
        return [BitConverter]::ToString($hash).Replace('-', '')
    }

    # Check if record is a success result
    [bool] IsSuccessResult([hashtable]$record) {
        if (-not $record.ContainsKey('Result')) {
            return $false
        }

        $result = $record['Result']
        if ([string]::IsNullOrEmpty($result)) {
            return $false
        }

        foreach ($indicator in $this.Options.SuccessIndicators) {
            if ($result -ieq $indicator -or $result -ilike "*$indicator*") {
                # Track filtered result types
                if (-not $this.Stats.FilteredResultTypes.ContainsKey($result)) {
                    $this.Stats.FilteredResultTypes[$result] = 0
                }
                $this.Stats.FilteredResultTypes[$result]++
                return $true
            }
        }
        return $false
    }

    # Check if record is duplicate
    [bool] IsDuplicate([hashtable]$record) {
        if (-not $this.Options.RemoveDuplicates) {
            return $false
        }

        $hash = $this.CalculateRecordHash($record)
        if ($this.SeenHashes.Contains($hash)) {
            return $true
        }

        $this.SeenHashes.Add($hash) | Out-Null
        return $false
    }

    # Validate required fields
    [bool] ValidateRecord([hashtable]$record) {
        if (-not $this.Options.ValidateFields) {
            return $true
        }

        foreach ($field in $this.Options.RequiredFields) {
            if (-not $record.ContainsKey($field) -or [string]::IsNullOrEmpty($record[$field])) {
                return $false
            }
        }
        return $true
    }

    # Sanitize record data
    [void] SanitizeRecord([hashtable]$record) {
        if (-not $this.Options.SanitizeData) {
            return
        }

        $needsSanitization = $false

        foreach ($key in @($record.Keys)) {
            $value = $record[$key]
            if ($value -is [string]) {
                $original = $value
                # Trim whitespace
                $value = $value.Trim()
                # Remove control characters except tab and newline
                $value = $value -replace '[^\x09\x0A\x0D\x20-\x7E\x80-\xFF]', ''
                # Normalize multiple spaces
                $value = $value -replace '\s+', ' '

                if ($original -ne $value) {
                    $record[$key] = $value
                    $needsSanitization = $true
                }
            }
        }

        if ($needsSanitization) {
            $this.Stats.DataSanitizationCount++
        }
    }

    # Process a single record
    [bool] ProcessRecord([hashtable]$record, [string[]]$headers) {
        $this.Stats.TotalRecordsProcessed++

        # Validate required fields
        if (-not $this.ValidateRecord($record)) {
            $this.Stats.InvalidRecordsSkipped++
            return $false
        }

        # Sanitize data
        $this.SanitizeRecord($record)

        # Check for duplicates
        if ($this.IsDuplicate($record)) {
            $this.Stats.DuplicatesRemoved++
            return $false
        }

        # Check if success result
        if ($this.Options.FilterSuccessResults -and $this.IsSuccessResult($record)) {
            $this.Stats.SuccessRecordsFiltered++
            # Write to success archive if enabled
            if ($this.SuccessWriter) {
                $this.WriteRecordToStream($this.SuccessWriter, $record, $headers)
            }
            return $false
        }

        # Record passes all filters
        $this.Stats.RecordsRetained++
        if ($this.CleanedWriter) {
            $this.WriteRecordToStream($this.CleanedWriter, $record, $headers)
        }
        return $true
    }

    # Write record to stream
    hidden [void] WriteRecordToStream([StreamWriter]$writer, [hashtable]$record, [string[]]$headers) {
        $values = @()
        foreach ($header in $headers) {
            $value = $record[$header]
            # Handle CSV escaping
            if ($value -match '[",\r\n]') {
                $value = '"' + ($value -replace '"', '""') + '"'
            }
            $values += $value
        }
        $writer.WriteLine(($values -join ','))
    }

    # Get summary report
    [hashtable] GetSummary() {
        return @{
            Statistics = $this.Stats.ToHashtable()
            Options = @{
                FilterSuccess = $this.Options.FilterSuccessResults
                RemoveDuplicates = $this.Options.RemoveDuplicates
                SanitizeData = $this.Options.SanitizeData
                ValidateFields = $this.Options.ValidateFields
            }
            DataQuality = @{
                RetentionRate = if ($this.Stats.TotalRecordsProcessed -gt 0) {
                    [Math]::Round(($this.Stats.RecordsRetained / $this.Stats.TotalRecordsProcessed) * 100, 2)
                } else { 0 }
                SuccessFilterRate = if ($this.Stats.TotalRecordsProcessed -gt 0) {
                    [Math]::Round(($this.Stats.SuccessRecordsFiltered / $this.Stats.TotalRecordsProcessed) * 100, 2)
                } else { 0 }
                DuplicateRate = if ($this.Stats.TotalRecordsProcessed -gt 0) {
                    [Math]::Round(($this.Stats.DuplicatesRemoved / $this.Stats.TotalRecordsProcessed) * 100, 2)
                } else { 0 }
            }
        }
    }
}

#endregion

#region Streaming CSV Processor Class

class StreamingCSVProcessor {
    # Configuration
    [int]$BatchSize
    [bool]$EnableGarbageCollection
    [int]$GCInterval = 50000
    [CSVPostProcessor]$PostProcessor

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

    # Main processing method - backward compatible
    [hashtable] ProcessFile([string]$filePath) {
        return $this.ProcessFile($filePath, $null)
    }

    [hashtable] ProcessFile([string]$filePath, [scriptblock]$recordFilter) {
        return $this.ProcessFile($filePath, $recordFilter, $false, $null)
    }

    # Enhanced processing with post-processing
    [hashtable] ProcessFile([string]$filePath, [scriptblock]$recordFilter, [bool]$enablePostProcessing, [CSVPostProcessingOptions]$postProcessingOptions) {
        $this.ProcessingStartTime = [DateTime]::Now
        $reader = $null
        $recordCount = 0
        $lineNumber = 0
        $currentBatch = [List[hashtable]]::new($this.BatchSize)

        # Initialize post-processor if enabled
        if ($enablePostProcessing) {
            if (-not $postProcessingOptions) {
                $postProcessingOptions = [CSVPostProcessingOptions]::new()
            }
            $this.PostProcessor = [CSVPostProcessor]::new($postProcessingOptions)
            $this.PostProcessor.InitializeOutputStreams($filePath)
        }

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

            # Write header to cleaned output if post-processing
            if ($this.PostProcessor -and $this.PostProcessor.CleanedWriter) {
                $this.PostProcessor.CleanedWriter.WriteLine($headerLine)
            }
            if ($this.PostProcessor -and $this.PostProcessor.SuccessWriter) {
                $this.PostProcessor.SuccessWriter.WriteLine($headerLine)
            }

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

                    # Post-process record if enabled
                    $keepRecord = $true
                    if ($this.PostProcessor) {
                        $keepRecord = $this.PostProcessor.ProcessRecord($record, $headers)
                    }

                    # Only add to statistics if record should be kept
                    if ($keepRecord) {
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
                    }

                    # Report progress periodically
                    if ($this.OnProgress -and ($lineNumber % 10000) -eq 0) {
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

            # Close post-processor streams
            if ($this.PostProcessor) {
                $this.PostProcessor.CloseOutputStreams()
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

            $result = @{
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

            # Add post-processing summary if enabled
            if ($this.PostProcessor) {
                $result['PostProcessing'] = $this.PostProcessor.GetSummary()
            }

            return $result
        }
        catch {
            $result = @{
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

            if ($this.PostProcessor) {
                $result['PostProcessing'] = $this.PostProcessor.GetSummary()
            }

            return $result
        }
        finally {
            if ($reader) {
                $reader.Close()
                $reader.Dispose()
            }

            if ($this.PostProcessor) {
                $this.PostProcessor.CloseOutputStreams()
            }

            # Final garbage collection
            if ($this.EnableGarbageCollection) {
                [GC]::Collect()
                [GC]::WaitForPendingFinalizers()
            }
        }
    }

    # Convenient method with post-processing enabled by default
    [hashtable] ProcessFileWithPostProcessing([string]$filePath) {
        return $this.ProcessFile($filePath, $null, $true, $null)
    }

    [hashtable] ProcessFileWithOptions([string]$filePath, [CSVPostProcessingOptions]$options) {
        return $this.ProcessFile($filePath, $null, $true, $options)
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
        $this.PostProcessor = $null
    }
}

#endregion

#region Helper Functions

function Test-StreamingCSVProcessor {
    <#
    .SYNOPSIS
        Test the streaming CSV processor with post-processing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [int]$BatchSize = 10000,

        [switch]$EnablePostProcessing
    )

    Write-Host "`n=== Streaming CSV Processor Test ===" -ForegroundColor Cyan
    Write-Host "File: $FilePath"
    Write-Host "Batch Size: $($BatchSize.ToString('N0'))"
    Write-Host "Post-Processing: $($EnablePostProcessing.IsPresent)`n"

    # Create processor
    $processor = [StreamingCSVProcessor]::new($BatchSize, $true)

    # Add progress callback
    $processor.OnProgress = {
        param($progressInfo)
        $estimatedTotal = $progressInfo.FileSizeMB * 10000
        $pct = if ($estimatedTotal -gt 0) {
            [Math]::Min(99, [Math]::Round(($progressInfo.RecordsProcessed / $estimatedTotal) * 100, 1))
        } else { 0 }
        Write-Progress -Activity "Processing CSV" `
            -Status "Records: $($progressInfo.RecordsProcessed.ToString('N0'))" `
            -PercentComplete $pct
    }

    # Process file
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    if ($EnablePostProcessing) {
        $result = $processor.ProcessFileWithPostProcessing($FilePath)
    } else {
        $result = $processor.ProcessFile($FilePath)
    }
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

    if ($result.PostProcessing) {
        Write-Host "`n=== Post-Processing Results ===" -ForegroundColor Yellow
        $pp = $result.PostProcessing
        Write-Host "Total Processed: $($pp.Statistics.TotalProcess

