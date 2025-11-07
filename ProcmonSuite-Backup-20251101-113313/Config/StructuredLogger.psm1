# Structured Logger Module for Procmon Analysis Suite
# Provides JSON-structured logging with levels and context correlation

#Requires -Version 7.2

enum LogLevel {
    TRACE = 0
    DEBUG = 1
    INFO = 2
    WARN = 3
    ERROR = 4
    FATAL = 5
}

class StructuredLogger {
    [string]$LogFilePath
    [LogLevel]$MinimumLevel
    [string]$SessionId
    [bool]$EnableConsoleOutput
    [bool]$EnableFileOutput
    [bool]$EnablePerformanceLogging
    [hashtable]$GlobalContext
    [System.IO.StreamWriter]$LogFileWriter
    [object]$LogLock

    StructuredLogger([hashtable]$Config) {
        $this.SessionId = $Config.Runtime.SessionId
        $this.MinimumLevel = [LogLevel]$Config.Logging.DefaultLevel
        $this.EnableConsoleOutput = $Config.Logging.EnableConsoleOutput
        $this.EnableFileOutput = $Config.Logging.EnableFileOutput
        $this.EnablePerformanceLogging = $Config.Logging.EnablePerformanceLogging
        $this.GlobalContext = @{}
        $this.LogLock = [System.Object]::new()

        if ($this.EnableFileOutput) {
            $this.InitializeLogFile($Config)
        }
    }

    [void] InitializeLogFile([hashtable]$Config) {
        try {
            # Ensure logs directory exists
            $logsDir = $Config.Directories.Logs
            if (-not (Test-Path $logsDir)) {
                New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
            }

            # Create log file path with session ID
            $logFileName = $Config.Logging.LogFilePattern -replace '{SessionId}', $this.SessionId -replace '{Date}', (Get-Date -Format 'yyyy-MM-dd')
            $this.LogFilePath = Join-Path $logsDir $logFileName

            # Use unique file names to avoid conflicts in tests
            $counter = 0
            while ((Test-Path $this.LogFilePath) -and $counter -lt 100) {
                $baseFileName = $Config.Logging.LogFilePattern -replace '{SessionId}', $this.SessionId -replace '{Date}', (Get-Date -Format 'yyyy-MM-dd')
                $baseFileName = $baseFileName -replace '\.log$', "-$counter.log"
                $this.LogFilePath = Join-Path $logsDir $baseFileName
                $counter++
            }

            # Initialize file writer with UTF8 encoding
            $this.LogFileWriter = [System.IO.StreamWriter]::new($this.LogFilePath, $true, [System.Text.Encoding]::UTF8)
            $this.LogFileWriter.AutoFlush = $true

            # Write initial log entry
            $this.LogInfo("Structured logging initialized", @{
                LogFile = $this.LogFilePath
                MinimumLevel = $this.MinimumLevel.ToString()
                SessionId = $this.SessionId
            })
        }
        catch {
            Write-Warning "Failed to initialize log file: $($_.Exception.Message)"
            $this.EnableFileOutput = $false
        }
    }

    [void] LogTrace([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::TRACE, $Message, $Context)
    }

    [void] LogDebug([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::DEBUG, $Message, $Context)
    }

    [void] LogInfo([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::INFO, $Message, $Context)
    }

    [void] LogWarn([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::WARN, $Message, $Context)
    }

    [void] LogError([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::ERROR, $Message, $Context)
    }

    [void] LogFatal([string]$Message, [hashtable]$Context = @{}) {
        $this.WriteLog([LogLevel]::FATAL, $Message, $Context)
    }

    [void] LogException([System.Exception]$Exception, [string]$Message = "", [hashtable]$Context = @{}) {
        $enhancedContext = $Context.Clone()
        $enhancedContext.ExceptionType = $Exception.GetType().Name -replace '^System\.', ''
        $enhancedContext.ExceptionMessage = $Exception.Message
        # Handle cases where StackTrace might be null or empty
        $enhancedContext.StackTrace = if ([string]::IsNullOrWhiteSpace($Exception.StackTrace)) {
            (Get-PSCallStack | Select-Object -Skip 1 | ForEach-Object { "$($_.Command) at $($_.Location)" }) -join "`n"
        } else {
            $Exception.StackTrace
        }

        $logMessage = if ([string]::IsNullOrEmpty($Message)) {
            "Exception occurred: $($Exception.Message)"
        } else {
            "$Message - Exception: $($Exception.Message)"
        }

        $this.LogError($logMessage, $enhancedContext)
    }

    [void] LogPerformance([string]$Operation, [double]$DurationMs, [hashtable]$Context = @{}) {
        if (-not $this.EnablePerformanceLogging) { return }

        $perfContext = $Context.Clone()
        $perfContext.Operation = $Operation
        $perfContext.DurationMs = $DurationMs
        # Use AwayFromZero rounding to match test expectations
        $perfContext.DurationSeconds = [Math]::Round(($DurationMs / 1000.0), 3, [System.MidpointRounding]::AwayFromZero)

        $this.LogInfo("Performance metric recorded", $perfContext)
    }

    [void] LogPhaseStart([string]$Phase, [hashtable]$Context = @{}) {
        $phaseContext = $Context.Clone()
        $phaseContext.Phase = $Phase
        $phaseContext.PhaseStatus = "Started"
        $phaseContext.StartTime = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

        $this.LogInfo("Analysis phase started", $phaseContext)

        # Also output to console for visibility
        if ($this.EnableConsoleOutput) {
            Write-Host "`n=== $Phase PHASE ===" -ForegroundColor Magenta
            Write-Host "Time: $(Get-Date -Format 'HH:mm:ss') | Session: $($this.SessionId)" -ForegroundColor Gray
        }
    }

    [void] LogPhaseComplete([string]$Phase, [double]$DurationSeconds, [hashtable]$Context = @{}) {
        $phaseContext = $Context.Clone()
        $phaseContext.Phase = $Phase
        $phaseContext.PhaseStatus = "Completed"
        $phaseContext.DurationSeconds = $DurationSeconds
        $phaseContext.DurationMs = $DurationSeconds * 1000
        $phaseContext.EndTime = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')

        $this.LogInfo("Analysis phase completed", $phaseContext)

        # Also output to console for visibility
        if ($this.EnableConsoleOutput) {
            Write-Host "$Phase completed in $([Math]::Round($DurationSeconds, 1)) seconds" -ForegroundColor Green
        }
    }

    [void] LogProgress([string]$Activity, [string]$Status, [int]$PercentComplete, [string]$CurrentOperation, [hashtable]$Context = @{}) {
        # Only log progress at certain intervals to avoid spam
        if ($PercentComplete % 25 -eq 0 -or $PercentComplete -eq 100) {
            $progressContext = $Context.Clone()
            $progressContext.Activity = $Activity
            $progressContext.Status = $Status
            $progressContext.PercentComplete = $PercentComplete
            $progressContext.CurrentOperation = $CurrentOperation

            $this.LogDebug("Progress update", $progressContext)
        }
    }

    [void] WriteLog([LogLevel]$Level, [string]$Message, [hashtable]$Context) {
        if ($Level -lt $this.MinimumLevel) { return }

        try {
            # Thread-safe logging
            [System.Threading.Monitor]::Enter($this.LogLock)

            $logEntry = $this.CreateLogEntry($Level, $Message, $Context)

            # Output to console
            if ($this.EnableConsoleOutput) {
                $this.WriteToConsole($Level, $Message, $logEntry)
            }

            # Output to file
            if ($this.EnableFileOutput -and $this.LogFileWriter) {
                $jsonEntry = $logEntry | ConvertTo-Json -Compress -Depth 10
                $this.LogFileWriter.WriteLine($jsonEntry)
                $this.LogFileWriter.Flush()  # Ensure immediate write to file for tests
            }
        }
        catch {
            # Fallback to basic output if structured logging fails
            Write-Warning "Structured logging failed: $($_.Exception.Message)"
            Write-Host "[$($Level.ToString())] $Message" -ForegroundColor Yellow
        }
        finally {
            [System.Threading.Monitor]::Exit($this.LogLock)
        }
    }

    [hashtable] CreateLogEntry([LogLevel]$Level, [string]$Message, [hashtable]$Context) {
        $entry = @{
            timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            level = $Level.ToString()
            message = $Message
            sessionId = $this.SessionId
            processId = [System.Diagnostics.Process]::GetCurrentProcess().Id
            threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
            machineName = [System.Environment]::MachineName
            context = @{}
        }

        # Merge global context
        foreach ($key in $this.GlobalContext.Keys) {
            $entry.context[$key] = $this.GlobalContext[$key]
        }

        # Merge provided context
        foreach ($key in $Context.Keys) {
            $entry.context[$key] = $Context[$key]
        }

        return $entry
    }

    [void] WriteToConsole([LogLevel]$Level, [string]$Message, [hashtable]$LogEntry) {
        $timestamp = (Get-Date).ToString('HH:mm:ss')
        $levelStr = $Level.ToString().PadRight(5)

        $color = switch ($Level) {
            ([LogLevel]::TRACE) { 'DarkGray' }
            ([LogLevel]::DEBUG) { 'Gray' }
            ([LogLevel]::INFO) { 'White' }
            ([LogLevel]::WARN) { 'Yellow' }
            ([LogLevel]::ERROR) { 'Red' }
            ([LogLevel]::FATAL) { 'Magenta' }
            default { 'White' }
        }

        Write-Host "[$timestamp] [$levelStr] $Message" -ForegroundColor $color

        # Show context for higher-level messages
        if ($Level -ge [LogLevel]::WARN -and $LogEntry.context.Count -gt 0) {
            $contextStr = ($LogEntry.context.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
            Write-Host "    Context: $contextStr" -ForegroundColor DarkGray
        }
    }

    [void] SetGlobalContext([hashtable]$Context) {
        foreach ($key in $Context.Keys) {
            $this.GlobalContext[$key] = $Context[$key]
        }
    }

    [void] RemoveGlobalContext([string]$Key) {
        if ($this.GlobalContext.ContainsKey($Key)) {
            $this.GlobalContext.Remove($Key)
        }
    }

    [void] SetMinimumLevel($Level) {
        if ($Level -is [string]) {
            $this.MinimumLevel = [LogLevel]$Level
        } else {
            $this.MinimumLevel = $Level
        }
        $this.LogInfo("Log level changed", @{ NewLevel = $this.MinimumLevel.ToString() })
    }

    [hashtable] GetLogStatistics() {
        $stats = @{
            SessionId = $this.SessionId
            LogFilePath = $this.LogFilePath
            MinimumLevel = $this.MinimumLevel.ToString()
            EnableConsoleOutput = $this.EnableConsoleOutput
            EnableFileOutput = $this.EnableFileOutput
            GlobalContextKeys = $this.GlobalContext.Keys -join ', '
        }

        if ($this.EnableFileOutput -and (Test-Path $this.LogFilePath)) {
            # Ensure all data is written to file before getting stats
            if ($this.LogFileWriter) {
                $this.LogFileWriter.Flush()
            }
            $logFile = Get-Item $this.LogFilePath
            $stats.LogFileSizeMB = [Math]::Round($logFile.Length / 1MB, 2)
            # Ensure minimum precision for small files
            if ($stats.LogFileSizeMB -eq 0 -and $logFile.Length -gt 0) {
                $stats.LogFileSizeMB = [Math]::Round($logFile.Length / 1MB, 6)
            }
            $stats.LogFileCreated = $logFile.CreationTime
            $stats.LogFileLastModified = $logFile.LastWriteTime
        }

        return $stats
    }

    [void] Dispose() {
        try {
            if ($this.LogFileWriter) {
                $this.LogInfo("Structured logging session ended", @{
                    SessionDuration = ([DateTime]::UtcNow - [DateTime]::Parse($this.GlobalContext.SessionStartTime)).TotalMinutes
                })
                $this.LogFileWriter.Flush()
                $this.LogFileWriter.Dispose()
            }
        }
        catch {
            Write-Warning "Error disposing structured logger: $($_.Exception.Message)"
        }
    }
}

# Factory function for creating structured logger
function New-StructuredLogger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [hashtable]$InitialContext = @{}
    )

    $logger = [StructuredLogger]::new($Config)

    # Set initial global context
    $initialGlobalContext = @{
        ApplicationName = $Config.Application.Name
        ApplicationVersion = $Config.Application.Version
        SessionStartTime = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OperatingSystem = [System.Environment]::OSVersion.ToString()
        ProcessorCount = [System.Environment]::ProcessorCount
    }

    # Merge with provided initial context
    foreach ($key in $InitialContext.Keys) {
        $initialGlobalContext[$key] = $InitialContext[$key]
    }

    $logger.SetGlobalContext($initialGlobalContext)

    return $logger
}

# Performance measurement wrapper
function Measure-LoggedOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [StructuredLogger]$Logger,

        [Parameter(Mandatory = $true)]
        [string]$OperationName,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [hashtable]$Context = @{}
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $Logger.LogDebug("Operation started", @{ Operation = $OperationName })

        $result = & $ScriptBlock

        $stopwatch.Stop()
        $Logger.LogPerformance($OperationName, $stopwatch.ElapsedMilliseconds, $Context)

        return $result
    }
    catch {
        $stopwatch.Stop()
        $Logger.LogException($_.Exception, "Operation failed: $OperationName", @{
            Operation = $OperationName
            DurationMs = $stopwatch.ElapsedMilliseconds
        })
        throw
    }
}

# Export functions and classes
Export-ModuleMember -Function @('New-StructuredLogger', 'Measure-LoggedOperation') -Variable @()
