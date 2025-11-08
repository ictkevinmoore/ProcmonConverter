#Requires -Version 5.1

# Load required .NET assemblies
Add-Type -AssemblyName System.Web

# Security Helper Function
function ConvertTo-SafeHTML {
    <#
    .SYNOPSIS
        Prevents XSS attacks by HTML-encoding user input
    .PARAMETER Text
        The text to HTML-encode
    .EXAMPLE
        ConvertTo-SafeHTML -Text '<script>alert("XSS")</script>'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Text = ""
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    return [System.Web.HttpUtility]::HtmlEncode($Text)
}

<#
.SYNOPSIS
    Professional HTML Report Generator for Procmon Analysis

.DESCRIPTION
    Generates enterprise-grade HTML reports with:
    - Tab-based navigation (Summary, Event Details, Charts)
    - Bootstrap 5 styling
    - DataTables for advanced sorting/filtering/export
    - Chart.js for professional visualizations
    - Responsive design with modern UI

.PARAMETER DataObject
    The processed data object containing events and summaries

.PARAMETER OutputPath
    Path where the HTML report will be saved

.PARAMETER SessionInfo
    Session information (Version, SessionId, etc.)

.PARAMETER ReportConfig
    Optional configuration object for customizing report generation. All configuration parameter names are case-insensitive.

.EXAMPLE
    # Example 1: Basic Usage - Generate a simple report from processed data
    $data = @{
        Events = $processedEvents
        TotalRecords = 15000
        Summary = @{
            ProcessTypes = @{ 'chrome.exe' = 5000; 'explorer.exe' = 3000 }
            Operations = @{ 'RegOpenKey' = 8000; 'CreateFile' = 7000 }
        }
    }
    $session = @{
        SessionId = 'PROC-2025-001'
        Version = '1.0'
        FilesProcessed = 1
        InputDirectory = 'C:\ProcmonData'
        StartTime = [DateTime]::UtcNow
    }
    $report = New-ProfessionalReport -DataObject $data -OutputPath ".\Reports\analysis-report.html" -SessionInfo $session

.EXAMPLE
    # Example 2: Batch Processing - Generate reports for multiple CSV files
    $csvFiles = Get-ChildItem -Path "C:\ProcmonData\*.csv"
    foreach ($file in $csvFiles) {
        $data = Import-Csv -Path $file.FullName | ConvertTo-DataObject
        $session = @{
            SessionId = "BATCH-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Version = '1.0'
            FilesProcessed = 1
            InputDirectory = $file.DirectoryName
            StartTime = [DateTime]::UtcNow
        }
        $outputPath = Join-Path ".\Reports" "$($file.BaseName)-report.html"
        New-ProfessionalReport -DataObject $data -OutputPath $outputPath -SessionInfo $session
        Write-Host "Generated report: $outputPath"
    }

.EXAMPLE
    # Example 3: Error Handling - Generate report with validation and error handling
    try {
        # Validate data object
        if (-not $dataObject.Events -or $dataObject.Events.Count -eq 0) {
            throw "No events found in data object"
        }

        $session = @{
            SessionId = "VALIDATED-$(New-Guid)"
            Version = '2.0'
            FilesProcessed = 3
            InputDirectory = 'C:\Analysis\Input'
            StartTime = [DateTime]::UtcNow.AddHours(-1)
        }

        $result = New-ProfessionalReport -DataObject $dataObject -OutputPath ".\output\validated-report.html" -SessionInfo $session

        if ($result.Success) {
            Write-Host "Report generated successfully: $($result.ReportPath)"
            Start-Process $result.ReportPath
        } else {
            Write-Error "Report generation failed: $($result.Error)"
        }
    }
    catch {
        Write-Error "Failed to generate report: $_"
    }

.EXAMPLE
    # Example 4: Large Dataset Analysis - Process and report on large Procmon captures
    # First, aggregate and summarize large dataset
    $events = @()
    $processCount = @{}
    $operationCount = @{}

    Get-ChildItem "C:\LargeCapture\*.csv" | ForEach-Object {
        Import-Csv $_.FullName | ForEach-Object {
            $events += $_
            $processCount[$_.ProcessName] = ($processCount[$_.ProcessName] ?? 0) + 1
            $operationCount[$_.Operation] = ($operationCount[$_.Operation] ?? 0) + 1
        }
    }

    $dataObject = @{
        Events = $events | Select-Object -First 5000  # Limit for report performance
        TotalRecords = $events.Count
        Summary = @{
            ProcessTypes = $processCount
            Operations = $operationCount
        }
    }

    $session = @{
        SessionId = "LARGE-DATASET-$(Get-Date -Format 'yyyy-MM-dd')"
        Version = '1.0'
        FilesProcessed = (Get-ChildItem "C:\LargeCapture\*.csv").Count
        InputDirectory = 'C:\LargeCapture'
        StartTime = [DateTime]::UtcNow.AddMinutes(-45)
    }

    New-ProfessionalReport -DataObject $dataObject -OutputPath ".\Reports\large-capture-analysis.html" -SessionInfo $session

.EXAMPLE
    # Example 5: Automated Scheduled Reporting - Generate daily summary reports
    # This example can be used in a scheduled task
    $reportDate = Get-Date -Format 'yyyy-MM-dd'
    $sourceDir = "C:\ProcmonCaptures\Daily"
    $outputDir = "C:\Reports\Daily"

    # Ensure output directory exists
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Process today's captures
    $todayFiles = Get-ChildItem -Path $sourceDir -Filter "*$reportDate*.csv"

    if ($todayFiles.Count -gt 0) {
        # Combine all captures for the day
        $allEvents = @()
        $processStats = @{}
        $operationStats = @{}

        foreach ($file in $todayFiles) {
            $csv = Import-Csv $file.FullName
            $allEvents += $csv

            $csv | Group-Object ProcessName | ForEach-Object {
                $processStats[$_.Name] = ($processStats[$_.Name] ?? 0) + $_.Count
            }

            $csv | Group-Object Operation | ForEach-Object {
                $operationStats[$_.Name] = ($operationStats[$_.Name] ?? 0) + $_.Count
            }
        }

        $dataObject = @{
            Events = $allEvents | Select-Object -First 5000
            TotalRecords = $allEvents.Count
            Summary = @{
                ProcessTypes = $processStats
                Operations = $operationStats
            }
        }

        $session = @{
            SessionId = "DAILY-SUMMARY-$reportDate"
            Version = '1.0'
            FilesProcessed = $todayFiles.Count
            InputDirectory = $sourceDir
            StartTime = [DateTime]::UtcNow.Date
        }

        $outputPath = Join-Path $outputDir "daily-summary-$reportDate.html"
        $result = New-ProfessionalReport -DataObject $dataObject -OutputPath $outputPath -SessionInfo $session

        # Optional: Send email notification
        if ($result.Success) {
            Write-Host "Daily report generated: $outputPath"
            # Send-MailMessage -To "admin@company.com" -Subject "Daily Procmon Report - $reportDate" `
            #     -Body "Report available at: $outputPath" -SmtpServer "smtp.company.com"
        }
    } else {
        Write-Warning "No capture files found for $reportDate"
    }

.EXAMPLE
    # Example 6: Case-Insensitive Configuration - All parameter names are case-insensitive
    $data = @{
        Events = $processedEvents
        TotalRecords = 1000
        Summary = @{
            ProcessTypes = @{ 'chrome.exe' = 500; 'notepad.exe' = 300 }
            Operations = @{ 'RegOpenKey' = 400; 'CreateFile' = 600 }
        }
    }
    $session = @{
        SessionId = 'CASE-INSENSITIVE-TEST'
        Version = '1.0'
        FilesProcessed = 1
        InputDirectory = 'C:\TestData'
        StartTime = [DateTime]::UtcNow
    }

    # All these configuration variations will work identically (case-insensitive)
    $config1 = @{ maxsamplesize = 1000; topitemscount = 5 }  # lowercase
    $config2 = @{ MAXSAMPLESIZE = 1000; TOPITEMSCOUNT = 5 }  # uppercase
    $config3 = @{ MaxSampleSize = 1000; TopItemsCount = 5 }  # mixed case

    $report1 = New-ProfessionalReport -DataObject $data -OutputPath ".\report1.html" -SessionInfo $session -ReportConfig $config1
    $report2 = New-ProfessionalReport -DataObject $data -OutputPath ".\report2.html" -SessionInfo $session -ReportConfig $config2
    $report3 = New-ProfessionalReport -DataObject $data -OutputPath ".\report3.html" -SessionInfo $session -ReportConfig $config3

    # All three reports will have identical configuration applied
#>

# Global configuration and constants
$script:DefaultConfig = @{
    MaxSampleSize = 5000
    TopItemsCount = 15
    TemplatePath = $null
    EnableCompression = $false
    CacheTemplates = $true
    Theme = 'auto'  # auto, light, dark
    OutputFormat = 'html'  # html, json, xml
    IncludeRawData = $false
    ChartConfig = @{
        Width = 400
        Height = 300
        ColorScheme = 'default'
        Animation = $true
    }
}

function New-ProfessionalReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo,

        [Parameter(Mandatory = $false)]
        [hashtable]$ReportConfig = @{}
    )

    # Merge with default configuration
    $config = Merge-ReportConfig -Config $ReportConfig

    # Input validation
    if (-not (Test-DataObject -DataObject $DataObject)) {
        throw "Invalid data object provided"
    }

    if (-not (Test-SessionInfo -SessionInfo $SessionInfo)) {
        throw "Invalid session information provided"
    }

    try {
        # Prepare and validate data
        $reportData = Prepare-ReportData -DataObject $DataObject -Config $config
        if (-not $reportData) {
            throw "Failed to prepare report data"
        }

        # Generate HTML content using modular approach
        $html = New-ReportHTML -ReportData $reportData -SessionInfo $SessionInfo -Config $config

        # Write to file with error handling
        $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force -ErrorAction Stop

        # Validate output file
        if (-not (Test-Path $OutputPath)) {
            throw "Failed to create output file: $OutputPath"
        }

        Write-Verbose "Report generated successfully: $OutputPath"

        return @{
            Success = $true
            ReportPath = $OutputPath
            Message = "Professional report generated successfully"
            DataSummary = $reportData.Summary
        }
    }
    catch {
        $errorMessage = "Report generation failed: $($_.Exception.Message)"
        Write-Error $errorMessage

        return @{
            Success = $false
            Error = $errorMessage
            ReportPath = $OutputPath
        }
    }
}

# Validation Functions
function Test-DataObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject
    )

    # Check if DataObject is a hashtable
    if ($DataObject -eq $null) {
        Write-Warning "DataObject is null"
        return $false
    }

    # Check for required properties
    $requiredProperties = @('Events', 'TotalRecords', 'Summary')
    foreach ($prop in $requiredProperties) {
        if (-not $DataObject.ContainsKey($prop)) {
            Write-Warning "DataObject missing required property: $prop"
            return $false
        }
    }

    # Validate Events
    if ($DataObject.Events -eq $null) {
        Write-Warning "DataObject.Events is null"
        return $false
    }

    # Validate Summary structure
    if (-not $DataObject.Summary.ContainsKey('ProcessTypes') -or
        -not $DataObject.Summary.ContainsKey('Operations')) {
        Write-Warning "DataObject.Summary missing required ProcessTypes or Operations"
        return $false
    }

    # Validate TotalRecords is numeric and non-negative
    if ($DataObject.TotalRecords -lt 0) {
        Write-Warning "DataObject.TotalRecords cannot be negative"
        return $false
    }

    return $true
}

function Test-SessionInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo
    )

    # Check if SessionInfo is a hashtable
    if ($SessionInfo -eq $null) {
        Write-Warning "SessionInfo is null"
        return $false
    }

    # Check for required properties
    $requiredProperties = @('SessionId', 'Version', 'FilesProcessed', 'InputDirectory', 'StartTime')
    foreach ($prop in $requiredProperties) {
        if (-not $SessionInfo.ContainsKey($prop)) {
            Write-Warning "SessionInfo missing required property: $prop"
            return $false
        }
    }

    # Validate FilesProcessed is non-negative
    if ($SessionInfo.FilesProcessed -lt 0) {
        Write-Warning "SessionInfo.FilesProcessed cannot be negative"
        return $false
    }

    # Validate StartTime is a valid DateTime
    if ($SessionInfo.StartTime -eq $null -or $SessionInfo.StartTime -isnot [DateTime]) {
        Write-Warning "SessionInfo.StartTime must be a valid DateTime object"
        return $false
    }

    return $true
}

# Configuration Function
function Get-DefaultReportConfig {
    [CmdletBinding()]
    param()

    return @{
        MaxSampleSize = 5000
        TopItemsCount = 15
        ChartColors = @{
            Primary = 'rgba(102, 126, 234, 0.8)'
            Secondary = 'rgba(118, 75, 162, 0.8)'
            Success = 'rgba(40, 167, 69, 0.8)'
            Info = 'rgba(23, 162, 184, 0.8)'
            Warning = 'rgba(255, 193, 7, 0.8)'
            Danger = 'rgba(220, 53, 69, 0.8)'
        }
        ColorPalette = @(
            'rgba(102, 126, 234, 0.8)',
            'rgba(118, 75, 162, 0.8)',
            'rgba(40, 167, 69, 0.8)',
            'rgba(255, 193, 7, 0.8)',
            'rgba(220, 53, 69, 0.8)',
            'rgba(23, 162, 184, 0.8)',
            'rgba(108, 117, 125, 0.8)',
            'rgba(255, 99, 132, 0.8)',
            'rgba(54, 162, 235, 0.8)',
            'rgba(255, 206, 86, 0.8)',
            'rgba(75, 192, 192, 0.8)',
            'rgba(153, 102, 255, 0.8)',
            'rgba(255, 159, 64, 0.8)',
            'rgba(201, 203, 207, 0.8)',
            'rgba(255, 99, 71, 0.8)'
        )
        NumericKeywords = @('pid', 'id', 'count', 'size', 'duration', 'time', 'length', 'number', 'num', 'index')
        PageLength = 25
        LengthMenu = @(@(10, 25, 50, 100, -1), @("10", "25", "50", "100", "All"))
    }
}

# Data Filtering Functions
function Filter-ProcmonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Events,

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeResults = @('SUCCESS'),

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeSuccessOnly
    )

    if ($ExcludeSuccessOnly -or $ExcludeResults.Count -gt 0) {
        $filtered = $Events | Where-Object {
            $result = if ($_.Result) { $_.Result } elseif ($_.Status) { $_.Status } else { "" }
            -not ($ExcludeResults -contains $result)
        }

        Write-Verbose "Filtered $($Events.Count - $filtered.Count) SUCCESS operations"
        return $filtered
    }

    return $Events
}

# Data Processing Functions
function Get-TopProcesses {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProcessTypes,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 15
    )

    return $ProcessTypes.GetEnumerator() |
        Sort-Object Value -Descending |
        Select-Object -First $TopCount
}

function Get-TopOperations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Operations,

        [Parameter(Mandatory = $false)]
        [int]$TopCount = 15
    )

    return $Operations.GetEnumerator() |
        Sort-Object Value -Descending |
        Select-Object -First $TopCount
}

function Get-SampleEvents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Events,

        [Parameter(Mandatory = $false)]
        [int]$MaxSampleSize = 5000
    )

    $sampleSize = [Math]::Min($MaxSampleSize, $Events.Count)
    return $Events | Select-Object -First $sampleSize
}

function Get-ReportInsights {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [array]$TopProcesses,

        [Parameter(Mandatory = $true)]
        [array]$TopOperations
    )

    $avgEventsPerProcess = if ($DataObject.Summary.ProcessTypes.Count -gt 0) {
        [Math]::Round($DataObject.TotalRecords / $DataObject.Summary.ProcessTypes.Count, 0)
    } else { 0 }

    $topProcess = $TopProcesses | Select-Object -First 1
    $topOperation = $TopOperations | Select-Object -First 1

    $processPercent = if ($DataObject.TotalRecords -gt 0 -and $topProcess) {
        [Math]::Round(($topProcess.Value / $DataObject.TotalRecords) * 100, 1)
    } else { 0 }

    return @{
        AverageEventsPerProcess = $avgEventsPerProcess
        TopProcess = $topProcess
        TopOperation = $topOperation
        ProcessPercentage = $processPercent
    }
}

# Chart Data Preparation Functions
function Get-ChartLabelsAndData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Items
    )

    $labels = ($Items | ForEach-Object {
        $escaped = $_.Key -replace "'", "\'"
        "'$escaped'"
    }) -join ','

    $data = ($Items | ForEach-Object { $_.Value }) -join ','

    return @{
        Labels = $labels
        Data = $data
    }
}

# HTML Generation Functions
function Get-HTMLHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SessionId,

        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    return @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Procmon Professional Analysis Report - $SessionId</title>

    <!-- Bootstrap 5 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- DataTables with Bootstrap 5 -->
    <link href="https://cdn.datatables.net/1.13.6/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <link href="https://cdn.datatables.net/buttons/2.4.1/css/buttons.bootstrap5.min.css" rel="stylesheet">

    <!-- Font Awesome -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">

    <style>
        :root {
            --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            --primary-solid: #4f46e5;
            --primary-hover: #4338ca;
            --card-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.06);
            --card-shadow-lg: 0 10px 25px rgba(0,0,0,0.12), 0 5px 10px rgba(0,0,0,0.08);
            --transition-smooth: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
            --transition-bounce: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        }

        /* ... existing styles ... */
    </style>
</head>
<body>
"@
}

function Get-HTMLFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    return @"
    <!-- Footer -->
    <div class="footer">
        <p class="mb-1"><strong>Ultimate Modular Procmon Analysis Suite</strong> v$Version</p>
        <p class="mb-0">
            <i class="fas fa-calendar-alt"></i> Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') |
            <i class="fas fa-server"></i> Computer: $env:COMPUTERNAME |
            <i class="fas fa-user"></i> User: $env:USERNAME
        </p>
    </div>
</body>
</html>
"@
}

# Core Report Generation Functions
function Merge-ReportConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    $merged = $script:DefaultConfig.Clone()

    # Case-insensitive configuration key matching
    foreach ($key in $Config.Keys) {
        $matchedKey = Find-MatchingConfigKey -Key $key -Config $merged
        if ($matchedKey) {
            $merged[$matchedKey] = $Config[$key]
        } else {
            Write-Warning "Unknown configuration parameter: $key (parameter names are case-insensitive)"
        }
    }
    return $merged
}

function Find-MatchingConfigKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $lowerKey = $Key.ToLower()

    foreach ($configKey in $Config.Keys) {
        if ($configKey.ToLower() -eq $lowerKey) {
            return $configKey
        }
    }

    return $null
}

function Prepare-ReportData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    try {
        # Extract and validate top processes
        $topProcesses = Get-TopProcesses -ProcessTypes $DataObject.Summary.ProcessTypes -TopCount $Config.TopItemsCount

        # Extract and validate top operations
        $topOperations = Get-TopOperations -Operations $DataObject.Summary.Operations -TopCount $Config.TopItemsCount

        # Sample events for performance
        $sampleEvents = Get-SampleEvents -Events $DataObject.Events -MaxSampleSize $Config.MaxSampleSize

        # Calculate insights
        $insights = Get-ReportInsights -DataObject $DataObject -TopProcesses $topProcesses -TopOperations $topOperations

        # Prepare chart data
        $processChartData = Get-ChartLabelsAndData -Items $topProcesses
        $operationChartData = Get-ChartLabelsAndData -Items $topOperations

        # Ensure we have fallback data for charts
        if ($topProcesses.Count -eq 0) {
            $processChartData = @{ Labels = "'No Data'"; Data = "0" }
        }
        if ($topOperations.Count -eq 0) {
            $operationChartData = @{ Labels = "'No Data'"; Data = "0" }
        }

        # Get FilesProcessed with fallback
        $filesProcessed = if ($DataObject.ContainsKey('FilesProcessed')) {
            $DataObject.FilesProcessed
        } else {
            1  # Default fallback
        }

        return @{
            TopProcesses = $topProcesses
            TopOperations = $topOperations
            SampleEvents = $sampleEvents
            Insights = $insights
            ProcessChartData = $processChartData
            OperationChartData = $operationChartData
            Summary = @{
                TotalRecords = $DataObject.TotalRecords
                FilesProcessed = $filesProcessed
                UniqueProcesses = $DataObject.Summary.ProcessTypes.Count
                OperationTypes = $DataObject.Summary.Operations.Count
            }
        }
    }
    catch {
        Write-Error "Failed to prepare report data: $($_.Exception.Message)"
        return $null
    }
}

function New-ReportHTML {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ReportData,

        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo,

        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    try {
        # Build HTML using StringBuilder for better performance
        $htmlBuilder = New-Object System.Text.StringBuilder

        # HTML Header
        $htmlBuilder.AppendLine("<!DOCTYPE html>") | Out-Null
        $htmlBuilder.AppendLine('<html lang="en">') | Out-Null
        $htmlBuilder.AppendLine("<head>") | Out-Null
        $htmlBuilder.AppendLine('    <meta charset="UTF-8">') | Out-Null
        $htmlBuilder.AppendLine('    <meta name="viewport" content="width=device-width, initial-scale=1.0">') | Out-Null
        $htmlBuilder.AppendFormat('    <title>Procmon Professional Analysis Report - {0}</title>', $SessionInfo.SessionId) | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # CSS and JS includes
        $htmlBuilder.AppendLine('    <!-- Bootstrap 5 -->') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">') | Out-Null
        $htmlBuilder.AppendLine('    <!-- DataTables with Bootstrap 5 -->') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdn.datatables.net/1.13.8/css/dataTables.bootstrap5.min.css" rel="stylesheet">') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdn.datatables.net/buttons/2.4.2/css/buttons.bootstrap5.min.css" rel="stylesheet">') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdn.datatables.net/searchpanes/2.2.0/css/searchPanes.bootstrap5.min.css" rel="stylesheet">') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdn.datatables.net/select/1.7.0/css/select.bootstrap5.min.css" rel="stylesheet">') | Out-Null
        $htmlBuilder.AppendLine('    <!-- Font Awesome -->') | Out-Null
        $htmlBuilder.AppendLine('    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">') | Out-Null

        # Inline CSS (could be moved to external file)
        $htmlBuilder.AppendLine('    <style>') | Out-Null
        $htmlBuilder.AppendLine('        /* Gates Foundation Theme Variables */') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="light"] {') | Out-Null
        $htmlBuilder.AppendLine('            --bg-primary: #f5f5f5;') | Out-Null
        $htmlBuilder.AppendLine('            --bg-secondary: #ffffff;') | Out-Null
        $htmlBuilder.AppendLine('            --bg-tertiary: #e8e9eb;') | Out-Null
        $htmlBuilder.AppendLine('            --text-primary: #2c3e50;') | Out-Null
        $htmlBuilder.AppendLine('            --text-secondary: #64748b;') | Out-Null
        $htmlBuilder.AppendLine('            --border-color: #cbd5e1;') | Out-Null
        $htmlBuilder.AppendLine('            --card-bg: #ffffff;') | Out-Null
        $htmlBuilder.AppendLine('            --modal-bg: #ffffff;') | Out-Null
        $htmlBuilder.AppendLine('            --modal-overlay: rgba(0, 0, 0, 0.5);') | Out-Null
        $htmlBuilder.AppendLine('            --primary-gradient: linear-gradient(135deg, #475569 0%, #334155 100%);') | Out-Null
        $htmlBuilder.AppendLine('            --primary-solid: #475569;') | Out-Null
        $htmlBuilder.AppendLine('            --primary-hover: #334155;') | Out-Null
        $htmlBuilder.AppendLine('            --accent-orange: #d97706;') | Out-Null
        $htmlBuilder.AppendLine('            --accent-orange-hover: #b45309;') | Out-Null
        $htmlBuilder.AppendLine('            --card-shadow: 0 1px 3px rgba(0,0,0,0.12), 0 1px 2px rgba(0,0,0,0.08);') | Out-Null
        $htmlBuilder.AppendLine('            --transition-smooth: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);') | Out-Null
        $htmlBuilder.AppendLine('        }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] {') | Out-Null
        $htmlBuilder.AppendLine('            --bg-primary: #1e293b;') | Out-Null
        $htmlBuilder.AppendLine('            --bg-secondary: #334155;') | Out-Null
        $htmlBuilder.AppendLine('            --bg-tertiary: #475569;') | Out-Null
        $htmlBuilder.AppendLine('            --text-primary: #f1f5f9;') | Out-Null
        $htmlBuilder.AppendLine('            --text-secondary: #cbd5e1;') | Out-Null
        $htmlBuilder.AppendLine('            --border-color: #475569;') | Out-Null
        $htmlBuilder.AppendLine('            --card-bg: #334155;') | Out-Null
        $htmlBuilder.AppendLine('            --modal-bg: #334155;') | Out-Null
        $htmlBuilder.AppendLine('            --modal-overlay: rgba(0, 0, 0, 0.75);') | Out-Null
        $htmlBuilder.AppendLine('            --primary-gradient: linear-gradient(135deg, #64748b 0%, #475569 100%);') | Out-Null
        $htmlBuilder.AppendLine('            --primary-solid: #64748b;') | Out-Null
        $htmlBuilder.AppendLine('            --primary-hover: #475569;') | Out-Null
        $htmlBuilder.AppendLine('            --accent-orange: #fb923c;') | Out-Null
        $htmlBuilder.AppendLine('            --accent-orange-hover: #f97316;') | Out-Null
        $htmlBuilder.AppendLine('            --card-shadow: 0 4px 12px rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.25);') | Out-Null
        $htmlBuilder.AppendLine('            --transition-smooth: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);') | Out-Null
        $htmlBuilder.AppendLine('        }') | Out-Null
        $htmlBuilder.AppendLine('        * { transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease; }') | Out-Null
        $htmlBuilder.AppendLine('        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: var(--bg-primary); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .metric-card { background: var(--card-bg); border-radius: 12px; padding: 1.5rem; box-shadow: var(--card-shadow); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .metric-card .value { font-size: 2rem; font-weight: 700; color: var(--primary-solid); }') | Out-Null
        $htmlBuilder.AppendLine('        .metric-card .label { font-size: 0.875rem; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin-top: 0.5rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .table-container { background: var(--card-bg); border-radius: 12px; padding: 1.5rem; box-shadow: var(--card-shadow); margin-bottom: 2rem; color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-container { background: var(--card-bg); border-radius: 12px; padding: 1.5rem; box-shadow: var(--card-shadow); min-height: 400px; }') | Out-Null
        $htmlBuilder.AppendLine('        thead th { background-color: var(--bg-tertiary) !important; color: var(--text-primary) !important; font-weight: 600; padding: 0.5rem; }') | Out-Null
        $htmlBuilder.AppendLine('        /* Column Filter Dropdowns with Checkboxes */') | Out-Null
        $htmlBuilder.AppendLine('        .column-filter-btn { width: 100%; padding: 0.5rem 0.75rem; border: 2px solid var(--border-color); border-radius: 6px; font-size: 0.875rem; background-color: var(--card-bg); color: var(--text-primary); font-weight: 500; cursor: pointer; transition: var(--transition-smooth); text-align: left; display: flex; justify-content: space-between; align-items: center; }') | Out-Null
        $htmlBuilder.AppendLine('        .column-filter-btn:hover { border-color: var(--primary-solid); box-shadow: 0 0 0 0.15rem rgba(79, 70, 229, 0.15); }') | Out-Null
        $htmlBuilder.AppendLine('        .column-filter-dropdown { position: absolute; top: 100%; left: 0; right: 0; background: var(--card-bg); border: 2px solid var(--border-color); border-radius: 6px; max-height: 300px; overflow-y: auto; z-index: 1000; display: none; box-shadow: var(--card-shadow); margin-top: 0.25rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .column-filter-dropdown.show { display: block; }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-option { padding: 0.5rem 0.75rem; display: flex; align-items: center; cursor: pointer; transition: background-color 0.2s; }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-option:hover { background-color: var(--bg-tertiary); }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-option input[type="checkbox"] { margin-right: 0.5rem; cursor: pointer; }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-option label { cursor: pointer; flex-grow: 1; margin: 0; color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-search { padding: 0.5rem; border-bottom: 1px solid var(--border-color); }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-search input { width: 100%; padding: 0.25rem 0.5rem; border: 1px solid var(--border-color); border-radius: 4px; background: var(--bg-primary); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-actions { padding: 0.5rem; border-top: 1px solid var(--border-color); display: flex; gap: 0.5rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-actions button { flex: 1; padding: 0.25rem 0.5rem; border: 1px solid var(--border-color); border-radius: 4px; background: var(--card-bg); color: var(--text-primary); cursor: pointer; font-size: 0.75rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-actions button:hover { background: var(--bg-tertiary); }') | Out-Null
        $htmlBuilder.AppendLine('        .filter-count { display: inline-block; margin-left: 0.5rem; background: var(--primary-solid); color: white; padding: 0.125rem 0.5rem; border-radius: 12px; font-size: 0.75rem; font-weight: 600; }') | Out-Null
        $htmlBuilder.AppendLine('        .table { margin-bottom: 0; color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .dt-buttons { margin-bottom: 0.75rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .dt-button { margin-left: 0.5rem !important; }') | Out-Null
        $htmlBuilder.AppendLine('        #clearFiltersBtn { margin-top: 0.25rem; }') | Out-Null
        $htmlBuilder.AppendLine('        /* Row Selection Styles */') | Out-Null
        $htmlBuilder.AppendLine('        .table tbody tr { cursor: pointer; transition: background-color 0.2s ease; }') | Out-Null
        $htmlBuilder.AppendLine('        .table tbody tr:hover { background-color: rgba(102, 126, 234, 0.1) !important; }') | Out-Null
        $htmlBuilder.AppendLine('        .table tbody tr:active { background-color: rgba(102, 126, 234, 0.2) !important; }') | Out-Null
        $htmlBuilder.AppendLine('        /* Detail View Modal */') | Out-Null
        $htmlBuilder.AppendLine('        .detail-modal .modal-dialog { max-width: 800px; }') | Out-Null
        $htmlBuilder.AppendLine('        .detail-modal .modal-content { background: var(--modal-bg); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        .detail-content { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .detail-item { background: var(--bg-tertiary); padding: 0.75rem; border-radius: 6px; border-left: 3px solid var(--primary-solid); }') | Out-Null
        $htmlBuilder.AppendLine('        .detail-item .label { font-size: 0.75rem; color: var(--text-secondary); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 0.25rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .detail-item .value { font-size: 0.95rem; color: var(--text-primary); font-family: "Courier New", monospace; word-break: break-all; }') | Out-Null
        $htmlBuilder.AppendLine('        /* DataTables Dark Mode */') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTables_wrapper { color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTable thead th { background-color: var(--bg-tertiary) !important; color: var(--text-primary) !important; }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTable tbody tr { background-color: var(--card-bg); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTable tbody tr:hover { background-color: var(--bg-tertiary) !important; }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTables_info, :root[data-theme="dark"] .dataTables_length label, :root[data-theme="dark"] .dataTables_filter label { color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTables_paginate .page-link { background-color: var(--card-bg); border-color: var(--border-color); color: var(--text-primary); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTables_paginate .page-link:hover { background-color: var(--bg-tertiary); border-color: var(--primary-solid); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .dataTables_paginate .page-item.active .page-link { background-color: var(--primary-solid); border-color: var(--primary-solid); }') | Out-Null
        $htmlBuilder.AppendLine('        /* Modal Dark Mode */') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .modal-content { background: var(--modal-bg); color: var(--text-primary); border-color: var(--border-color); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .modal-header { border-bottom-color: var(--border-color); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .modal-footer { border-top-color: var(--border-color); }') | Out-Null
        $htmlBuilder.AppendLine('        :root[data-theme="dark"] .btn-close { filter: invert(1); }') | Out-Null
        $htmlBuilder.AppendLine('    </style>') | Out-Null

        $htmlBuilder.AppendLine("</head>") | Out-Null
        $htmlBuilder.AppendLine("<body>") | Out-Null

        # Hero Header
        $htmlBuilder.AppendLine('    <div class="hero-header" style="background: var(--primary-gradient); color: white; padding: 2rem;">') | Out-Null
        $htmlBuilder.AppendLine('        <div class="d-flex justify-content-between align-items-center">') | Out-Null
        $htmlBuilder.AppendFormat('            <h1>Procmon Professional Analysis - {0}</h1>', $SessionInfo.SessionId) | Out-Null
        $htmlBuilder.AppendLine('            <button id="themeToggle" class="btn btn-outline-light btn-sm">') |

