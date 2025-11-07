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
    .\Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1 -InputDirectory "C:\Data\Converted"
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

    IntegratedParameters([string]$scriptRoot) {
        $this.StartTime = [DateTime]::UtcNow
        $this.ScriptRoot = $scriptRoot
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
            }
            'LowMemory' {
                $this.BatchSize = 10000
                $this.EnableRealTimeProgress = $false
            }
            'Enterprise' {
                $this.BatchSize = 100000
                $this.EnableRealTimeProgress = $true
            }
            Default {
                $this.BatchSize = 25000
                $this.EnableRealTimeProgress = $true
            }
        }
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
        $allStatistics = @{
            ProcessTypes = @{}
            Operations = @{}
            Results = @{}
        }
        $totalRecords = 0
        $fileCounter = 0

        foreach ($file in $csvFiles) {
            $fileCounter++
            Write-Host "  [$fileCounter/$($csvFiles.Count)] Processing: $($file.Name)..." -ForegroundColor Gray

            $result = $processor.ProcessFile($file.FullName)

            if ($result.Success) {
                $totalRecords += $result.RecordCount
                Write-Host "    [PASS] Processed $($result.RecordCount.ToString('N0')) records" -ForegroundColor DarkGreen

                foreach ($kvp in $result.Statistics.ProcessTypes.GetEnumerator()) {
                    if ($allStatistics.ProcessTypes.ContainsKey($kvp.Key)) {
                        $allStatistics.ProcessTypes[$kvp.Key] += $kvp.Value
                    } else {
                        $allStatistics.ProcessTypes[$kvp.Key] = $kvp.Value
                    }
                }

                foreach ($kvp in $result.Statistics.Operations.GetEnumerator()) {
                    if ($allStatistics.Operations.ContainsKey($kvp.Key)) {
                        $allStatistics.Operations[$kvp.Key] += $kvp.Value
                    } else {
                        $allStatistics.Operations[$kvp.Key] = $kvp.Value
                    }
                }

                if ($result.Statistics.Results) {
                    foreach ($kvp in $result.Statistics.Results.GetEnumerator()) {
                        if ($allStatistics.Results.ContainsKey($kvp.Key)) {
                            $allStatistics.Results[$kvp.Key] += $kvp.Value
                        } else {
                            $allStatistics.Results[$kvp.Key] = $kvp.Value
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
        Write-Host "  [PASS] Unique processes: $($allStatistics.ProcessTypes.Count)" -ForegroundColor Green
        Write-Host "  [PASS] Unique operations: $($allStatistics.Operations.Count)" -ForegroundColor Green

        Write-Host "`n[5/5] Generating professional HTML report..." -ForegroundColor Yellow

        $sampleEvents = @()
        $sampleLimit = [Math]::Min(5000, $totalRecords)

        if ($csvFiles.Count -gt 0) {
            $firstFile = $csvFiles[0]
            $reader = [System.IO.StreamReader]::new($firstFile.FullName)
            $headerLine = $reader.ReadLine()
            $headers = $headerLine -split ',' | ForEach-Object { $_.Trim('"') }

            $count = 0
            while (-not $reader.EndOfStream -and $count -lt $sampleLimit) {
                $line = $reader.ReadLine()
                if ([string]::IsNullOrEmpty($line)) { continue }

                $values = $line -split ','
                $record = [PSCustomObject]@{}

                for ($i = 0; $i -lt [Math]::Min($headers.Count, $values.Count); $i++) {
                    $record | Add-Member -MemberType NoteProperty -Name $headers[$i] -Value $values[$i].Trim('"')
                }

                $sampleEvents += $record
                $count++
            }

            $reader.Close()
            $reader.Dispose()
        }

        $dataObject = @{
            Events = $sampleEvents
            TotalRecords = $totalRecords
            FilesProcessed = $csvFiles.Count
            Summary = @{
                ProcessTypes = $allStatistics.ProcessTypes
                Operations = $allStatistics.Operations
                Results = $allStatistics.Results
            }
        }

        $sessionInfo = @{
            SessionId = $Script:SessionId
            Version = '12.0-Integrated'
            FilesProcessed = $csvFiles.Count
            InputDirectory = $Parameters.InputDirectory
            StartTime = $Parameters.StartTime
        }

        $reportPath = Join-Path $Parameters.OutputDirectory "Procmon-Analysis-Report-$Script:SessionId.html"

        $reportResult = New-ProfessionalReport -DataObject $dataObject -OutputPath $reportPath -SessionInfo $sessionInfo

        if ($reportResult.Success) {
            Write-Host "  [PASS] Report generated successfully!" -ForegroundColor Green
            Write-Host "  [INFO] Report location: $($reportResult.ReportPath)" -ForegroundColor Cyan

            $duration = ([DateTime]::UtcNow - $Parameters.StartTime).TotalSeconds
            $recordsPerSecond = [Math]::Round($totalRecords / $duration, 0)

            Write-Host "`n============================================================================" -ForegroundColor Green
            Write-Host "                    PROCESSING COMPLETE                                     " -ForegroundColor Green
            Write-Host "============================================================================" -ForegroundColor Green
            Write-Host "  Total Records: $($totalRecords.ToString('N0'))" -ForegroundColor Green
            Write-Host "  Files Processed: $($csvFiles.Count)" -ForegroundColor Green
            Write-Host "  Duration: $($duration.ToString('F2')) seconds" -ForegroundColor Green
            Write-Host "  Performance: $($recordsPerSecond.ToString('N0')) records/sec" -ForegroundColor Green
            Write-Host "============================================================================`n" -ForegroundColor Green

            return @{
                Success = $true
                TotalRecords = $totalRecords
                ReportPath = $reportResult.ReportPath
                Duration = $duration
            }
        } else {
            throw "Report generation failed: $($reportResult.Error)"
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

