<#
.SYNOPSIS
    Logging module for Professional Report Generator

.DESCRIPTION
    Provides structured logging capabilities with multiple output targets,
    log levels, and performance monitoring.

.NOTES
    Version: 1.0
    Date: November 8, 2025
#>

using namespace System.Collections.Generic
using namespace System.Diagnostics

enum LogLevel {
    DEBUG
    INFO
    WARNING
    ERROR
    CRITICAL
}

class LogEntry {
    [DateTime]$Timestamp
    [LogLevel]$Level
    [string]$Message
    [string]$Source
    [string]$Category
    [hashtable]$Context
    [Exception]$Exception

    LogEntry([LogLevel]$level, [string]$message, [string]$source, [string]$category, [hashtable]$context, [Exception]$exception) {
        $this.Timestamp = [DateTime]::UtcNow
        $this.Level = $level
        $this.Message = $message
        $this.Source = $source
        $this.Category = $category
        $this.Context = $context
        $this.Exception = $exception
    }

    [string]ToString() {
        $timestamp = $this.Timestamp.ToString("yyyy-MM-dd HH:mm:ss.fff")
        $level = $this.Level.ToString().PadRight(8)
        $source = if ($this.Source) { "[$($this.Source)]" } else { "" }
        $category = if ($this.Category) { "[$($this.Category)]" } else { "" }

        return "$timestamp $level $source$category $($this.Message)"
    }

    [string]ToJson() {
        $obj = @{
            timestamp = $this.Timestamp.ToString("o")
            level = $this.Level.ToString()
            message = $this.Message
            source = $this.Source
            category = $this.Category
            context = $this.Context
        }

        if ($this.Exception) {
            $obj.exception = @{
                type = $this.Exception.GetType().FullName
                message = $this.Exception.Message
                stackTrace = $this.Exception.StackTrace
            }
        }

        return $obj | ConvertTo-Json -Compress
    }
}

class ReportLogger {
    [LogLevel]$MinimumLevel
    [List[LogEntry]]$LogEntries
    [string]$LogFilePath
    [bool]$LogToFile
    [bool]$LogToConsole
    [object]$LockObject
    [hashtable]$PerformanceCounters

    ReportLogger() {
        $this.MinimumLevel = [LogLevel]::INFO
        $this.LogEntries = [List[LogEntry]]::new()
        $this.LogToFile = $true
        $this.LogToConsole = $true
        $this.LockObject = [object]::new()
        $this.PerformanceCounters = @{}
    }

    [void]Configure([hashtable]$config) {
        if ($config.ContainsKey('LogLevel')) {
            $this.MinimumLevel = [LogLevel]::Parse([LogLevel], $config.LogLevel)
        }

        if ($config.ContainsKey('LogToFile')) {
            $this.LogToFile = [bool]$config.LogToFile
        }

        if ($config.ContainsKey('LogPath')) {
            $this.LogFilePath = $config.LogPath
        }

        if ($config.ContainsKey('LogToConsole')) {
            $this.LogToConsole = [bool]$config.LogToConsole
        }
    }

    [void]Log([LogLevel]$level, [string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null, [Exception]$exception = $null) {
        if ($level -lt $this.MinimumLevel) {
            return
        }

        $entry = [LogEntry]::new($level, $message, $source, $category, $context, $exception)

        lock ($this.LockObject) {
            $this.LogEntries.Add($entry)

            # Keep only last 1000 entries in memory
            if ($this.LogEntries.Count -gt 1000) {
                $this.LogEntries.RemoveAt(0)
            }
        }

        # Write to console
        if ($this.LogToConsole) {
            $this.WriteToConsole($entry)
        }

        # Write to file
        if ($this.LogToFile -and -not [string]::IsNullOrEmpty($this.LogFilePath)) {
            $this.WriteToFile($entry)
        }
    }

    [void]Debug([string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null) {
        $this.Log([LogLevel]::DEBUG, $message, $source, $category, $context)
    }

    [void]Info([string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null) {
        $this.Log([LogLevel]::INFO, $message, $source, $category, $context)
    }

    [void]Warning([string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null) {
        $this.Log([LogLevel]::WARNING, $message, $source, $category, $context)
    }

    [void]Error([string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null, [Exception]$exception = $null) {
        $this.Log([LogLevel]::ERROR, $message, $source, $category, $context, $exception)
    }

    [void]Critical([string]$message, [string]$source = "", [string]$category = "", [hashtable]$context = $null, [Exception]$exception = $null) {
        $this.Log([LogLevel]::CRITICAL, $message, $source, $category, $context, $exception)
    }

    [void]WriteToConsole([LogEntry]$entry) {
        $color = switch ($entry.Level) {
            ([LogLevel]::DEBUG) { 'Gray' }
            ([LogLevel]::INFO) { 'White' }
            ([LogLevel]::WARNING) { 'Yellow' }
            ([LogLevel]::ERROR) { 'Red' }
            ([LogLevel]::CRITICAL) { 'Magenta' }
            default { 'White' }
        }

        $message = $entry.ToString()
        Write-Host $message -ForegroundColor $color
    }

    [void]WriteToFile([LogEntry]$entry) {
        try {
            # Ensure directory exists
            $directory = [System.IO.Path]::GetDirectoryName($this.LogFilePath)
            if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path $directory)) {
                New-Item -Path $directory -ItemType Directory -Force | Out-Null
            }

            $entry.ToString() | Out-File -FilePath $this.LogFilePath -Append -Encoding UTF8
        }
        catch {
            # Don't throw exceptions from logging
            Write-Warning "Failed to write to log file: $($_.Exception.Message)"
        }
    }

    [void]StartPerformanceTimer([string]$operationName) {
        $this.PerformanceCounters[$operationName] = @{
            StartTime = [DateTime]::UtcNow
            Stopwatch = [Stopwatch]::StartNew()
        }
        $this.Debug("Started performance timer for: $operationName")
    }

    [void]StopPerformanceTimer([string]$operationName) {
        if ($this.PerformanceCounters.ContainsKey($operationName)) {
            $timer = $this.PerformanceCounters[$operationName]
            $timer.Stopwatch.Stop()

            $duration = $timer.Stopwatch.Elapsed
            $this.PerformanceCounters.Remove($operationName)

            $this.Info("Performance: $operationName completed in $($duration.TotalMilliseconds)ms",
                      "Performance", "Timer", @{
                          Operation = $operationName
                          DurationMs = $duration.TotalMilliseconds
                          StartTime = $timer.StartTime
                          EndTime = [DateTime]::UtcNow
                      })
        }
    }

    [LogEntry[]]GetLogEntries([LogLevel]$minLevel = [LogLevel]::DEBUG, [int]$maxEntries = 100) {
        return $this.LogEntries |
            Where-Object { $_.Level -ge $minLevel } |
            Sort-Object Timestamp -Descending |
            Select-Object -First $maxEntries
    }

    [hashtable]GetPerformanceStats() {
        return @{
            TotalLogEntries = $this.LogEntries.Count
            LogFilePath = $this.LogFilePath
            MinimumLevel = $this.MinimumLevel.ToString()
            ActiveTimers = $this.PerformanceCounters.Keys.Count
        }
    }

    [void]Flush() {
        # Ensure all pending writes are completed
        if ($this.LogToFile -and -not [string]::IsNullOrEmpty($this.LogFilePath)) {
            # Force flush by writing an empty line
            try {
                "" | Out-File -FilePath $this.LogFilePath -Append -Encoding UTF8
            }
            catch {
                # Ignore flush errors
            }
        }
    }

    [void]Clear() {
        lock ($this.LockObject) {
            $this.LogEntries.Clear()
        }
    }
}

# Module-level logger instance
$script:GlobalLogger = $null

# Module functions
function New-ReportLogger {
    <#
    .SYNOPSIS
        Creates a new ReportLogger instance

    .PARAMETER Config
        Configuration hashtable for the logger

    .EXAMPLE
        $logger = New-ReportLogger -Config @{ LogLevel = 'DEBUG'; LogToFile = $true }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    $logger = [ReportLogger]::new()
    $logger.Configure($Config)

    # Set as global logger if not already set
    if (-not $script:GlobalLogger) {
        $script:GlobalLogger = $logger
    }

    return $logger
}

function Get-ReportLogger {
    <#
    .SYNOPSIS
        Gets the global logger instance

    .EXAMPLE
        $logger = Get-ReportLogger
    #>
    [CmdletBinding()]
    param()

    if (-not $script:GlobalLogger) {
        $script:GlobalLogger = New-ReportLogger
    }

    return $script:GlobalLogger
}

function Write-ReportLog {
    <#
    .SYNOPSIS
        Writes a log entry using the global logger

    .PARAMETER Level
        Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)

    .PARAMETER Message
        Log message

    .PARAMETER Source
        Source of the log entry

    .PARAMETER Category
        Category of the log entry

    .PARAMETER Context
        Additional context data

    .PARAMETER Exception
        Exception object if applicable

    .EXAMPLE
        Write-ReportLog -Level INFO -Message "Processing started" -Source "DataProcessor"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [LogLevel]$Level,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Source = "",

        [Parameter(Mandatory = $false)]
        [string]$Category = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = $null,

        [Parameter(Mandatory = $false)]
        [Exception]$Exception = $null
    )

    $logger = Get-ReportLogger
    $logger.Log($Level, $Message, $Source, $Category, $Context, $Exception)
}

function Start-PerformanceTimer {
    <#
    .SYNOPSIS
        Starts a performance timer

    .PARAMETER OperationName
        Name of the operation to time

    .EXAMPLE
        Start-PerformanceTimer -OperationName "DataProcessing"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName
    )

    $logger = Get-ReportLogger
    $logger.StartPerformanceTimer($OperationName)
}

function Stop-PerformanceTimer {
    <#
    .SYNOPSIS
        Stops a performance timer and logs the duration

    .PARAMETER OperationName
        Name of the operation that was timed

    .EXAMPLE
        Stop-PerformanceTimer -OperationName "DataProcessing"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName
    )

    $logger = Get-ReportLogger
    $logger.StopPerformanceTimer($OperationName)
}

# Export module members
Export-ModuleMember -Function @(
    'New-ReportLogger',
    'Get-ReportLogger',
    'Write-ReportLog',
    'Start-PerformanceTimer',
    'Stop-PerformanceTimer'
) -Variable @() -Alias @()

