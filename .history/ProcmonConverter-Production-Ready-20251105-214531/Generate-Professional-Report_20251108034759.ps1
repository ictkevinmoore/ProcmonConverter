#Requires -Version 5.1

<#
.SYNOPSIS
    Enhanced Professional HTML Report Generator with Full Analytics Integration

.DESCRIPTION
    Generates enterprise-grade HTML reports with:
    - Executive Summary with health scoring
    - Pattern Recognition analysis
    - Advanced Analytics with ML/AI
    - ML Analytics insights
    - Interactive tab-based navigation
    - Full integration with all analytics engines

.NOTES
    Version: 3.0-Enhanced-Analytics
    Date: November 6, 2025
    Enhancements: Full ML/AI analytics integration, 6-tab dashboard
#>

# Load required .NET assemblies
Add-Type -AssemblyName System.Web

# Import Analytics Engines
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source analytics engines with quoted paths to handle spaces
. "$(Join-Path $scriptPath 'StreamingCSVProcessor.ps1')"
. "$(Join-Path $scriptPath 'AdvancedAnalyticsEngine.ps1')"
. "$(Join-Path $scriptPath 'PatternRecognitionEngine.ps1')"
. "$(Join-Path $scriptPath 'ExecutiveSummaryGenerator.ps1')"

Write-Verbose "All analytics engines loaded successfully"

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
    $csvFiles = Get-ChildItem -Path "C:\Users\ictke\OneDrive\Desktop\November Script Back-up\ProcmonConverter-Production-Ready-20251105-214531\Data\Converted*.csv"
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
        Write-Verbose "Preparing report data..."
        $reportData = Prepare-ReportData -DataObject $DataObject -Config $config
        if (-not $reportData) {
            throw "Failed to prepare report data"
        }
        Write-Verbose "Report data prepared successfully."

        Write-Verbose "Generating HTML content..."
        $html = New-ReportHTML -ReportData $reportData -SessionInfo $SessionInfo -Config $config
        Write-Verbose "HTML content generated successfully."

        Write-Verbose "Writing HTML to file: $OutputPath"
        $html | Out-File -FilePath $OutputPath -Encoding UTF8 -Force -ErrorAction Stop
        Write-Verbose "HTML written to file successfully."

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
        $errorMessage = "Report generation failed: $($_.Exception.Message) at $($_.InvocationInfo.ScriptLineNumber)"
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
        # PHASE 3: ANALYTICS ENGINE INTEGRATION
        Write-Verbose "Initializing analytics engines..."

        # Instantiate analytics engines
        $analyticsEngine = [AdvancedAnalyticsEngine]::new()
        $patternEngine = [PatternRecognitionEngine]::new()
        $summaryGenerator = [ExecutiveSummaryGenerator]::new()

        # Configure summary generator
        $summaryConfig = [ReportConfiguration]::new()
        $summaryConfig.SummaryDepth = "Standard"
        $summaryConfig.SummaryMode = "Executive"
        $summaryGenerator.Config = $summaryConfig

        # Process data through analytics pipeline
        Write-Verbose "Running analytics pipeline..."
        $processedDataForAnalytics = @{
            RecordCount = $ReportData.Summary.TotalRecords
            Statistics = @{
                ProcessTypes = $DataObject.Summary.ProcessTypes
                Operations = $DataObject.Summary.Operations
                Results = @{}
            }
        }

        # Run analytics
        $analytics = $analyticsEngine.AnalyzeData($processedDataForAnalytics)
        $patterns = $patternEngine.AnalyzePatterns($processedDataForAnalytics)

        Write-Verbose "Analytics complete. Health Score: $($analytics.HealthScore), Patterns Detected: $($patterns.DetectedPatterns.Count)"

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
        $htmlBuilder.AppendLine('        /* Chart Thumbnail Styles */') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail-container { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; margin-top: 1rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail { background: var(--card-bg); border-radius: 12px; padding: 1rem; box-shadow: var(--card-shadow); cursor: pointer; transition: var(--transition-smooth); border: 2px solid transparent; }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail:hover { transform: translateY(-4px); box-shadow: 0 8px 24px rgba(0,0,0,0.15); border-color: var(--primary-solid); }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail h5 { margin-bottom: 0.75rem; color: var(--text-primary); font-size: 1rem; font-weight: 600; display: flex; align-items: center; gap: 0.5rem; }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail canvas { width: 100% !important; height: 200px !important; }') | Out-Null
        $htmlBuilder.AppendLine('        .chart-thumbnail-badge { background: var(--primary-solid); color: white; padding: 0.25rem 0.75rem; border-radius: 12px; font-size: 0.75rem; }') | Out-Null
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
        $htmlBuilder.AppendLine('            <button id="themeToggle" class="btn btn-outline-light btn-sm">') | Out-Null
        $htmlBuilder.AppendLine('                <i class="fas fa-moon" id="darkIcon"></i>') | Out-Null
        $htmlBuilder.AppendLine('                <i class="fas fa-sun" id="lightIcon" style="display:none;"></i>') | Out-Null
        $htmlBuilder.AppendLine('                <span id="themeText" class="ms-2">Dark Mode</span>') | Out-Null
        $htmlBuilder.AppendLine('            </button>') | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null
        $htmlBuilder.AppendLine('    </div>') | Out-Null

        # Summary Section
        $htmlBuilder.AppendLine('    <div class="container-fluid py-4">') | Out-Null
        $htmlBuilder.AppendLine('        <div class="row g-4 mb-4">') | Out-Null
        $htmlBuilder.AppendFormat('            <div class="col-md-3"><div class="metric-card"><div class="value">{0:N0}</div><div class="label">Total Records</div></div></div>', $ReportData.Summary.TotalRecords) | Out-Null
        $htmlBuilder.AppendFormat('            <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Files Processed</div></div></div>', $ReportData.Summary.FilesProcessed) | Out-Null
        $htmlBuilder.AppendFormat('            <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Unique Processes</div></div></div>', $ReportData.Summary.UniqueProcesses) | Out-Null
        $htmlBuilder.AppendFormat('            <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Operation Types</div></div></div>', $ReportData.Summary.OperationTypes) | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null

        # PHASE 2: 6-TAB NAVIGATION STRUCTURE (Consolidated ML Analytics into Advanced Analytics)
        $htmlBuilder.AppendLine('        <!-- 6-Tab Navigation Structure - Gold Standard -->') | Out-Null
        $htmlBuilder.AppendLine('        <ul class="nav nav-tabs" id="reportTabs" role="tablist">') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link active" id="tab-detailed-btn" data-bs-toggle="tab" data-bs-target="#tab-detailed" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-table-list me-2"></i>Detailed Analysis') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link" id="tab-summary-btn" data-bs-toggle="tab" data-bs-target="#tab-summary" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-briefcase me-2"></i>Executive Summary') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link" id="tab-patterns-btn" data-bs-toggle="tab" data-bs-target="#tab-patterns" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-brain me-2"></i>Pattern Recognition') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link" id="tab-analytics-btn" data-bs-toggle="tab" data-bs-target="#tab-analytics" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-chart-line me-2"></i>Advanced Analytics') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link" id="tab-events-btn" data-bs-toggle="tab" data-bs-target="#tab-events" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-table me-2"></i>Event Details') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('            <li class="nav-item" role="presentation">') | Out-Null
        $htmlBuilder.AppendLine('                <button class="nav-link" id="tab-charts-btn" data-bs-toggle="tab" data-bs-target="#tab-charts" type="button" role="tab">') | Out-Null
        $htmlBuilder.AppendLine('                    <i class="fas fa-chart-pie me-2"></i>Charts') | Out-Null
        $htmlBuilder.AppendLine('                </button>') | Out-Null
        $htmlBuilder.AppendLine('            </li>') | Out-Null
        $htmlBuilder.AppendLine('        </ul>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB CONTENT CONTAINER
        $htmlBuilder.AppendLine('        <div class="tab-content mt-4" id="reportTabContent">') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 1: DETAILED ANALYSIS (NEW UNIFIED TABLE)
        $htmlBuilder.AppendLine('            <!-- Tab 1: Detailed Analysis - Unified Table -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade show active" id="tab-detailed" role="tabpanel">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="table-container">') | Out-Null
        $htmlBuilder.AppendLine('                    <h3><i class="fas fa-table-list me-2"></i>Detailed Analysis - All Insights Combined</h3>') | Out-Null
        $htmlBuilder.AppendLine('                    <p class="text-muted">Comprehensive view of all analytics including Executive Summary, Pattern Recognition, Advanced Analytics, and ML Predictions</p>') | Out-Null
        $htmlBuilder.AppendLine('                    <table id="detailedAnalysisTable" class="table table-striped table-hover">') | Out-Null
        $htmlBuilder.AppendLine('                        <thead>') | Out-Null
        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <th>Category</th>') | Out-Null
        $htmlBuilder.AppendLine('                                <th>Type</th>') | Out-Null
        $htmlBuilder.AppendLine('                                <th>Description</th>') | Out-Null
        $htmlBuilder.AppendLine('                                <th>Severity/Score</th>') | Out-Null
        $htmlBuilder.AppendLine('                                <th>Details</th>') | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null
        $htmlBuilder.AppendLine('                        </thead>') | Out-Null
        $htmlBuilder.AppendLine('                        <tbody>') | Out-Null

        # Build unified data rows
        # 1. Executive Summary - Health Score
        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-briefcase text-primary me-2"></i>Executive Summary</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Health Score</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Overall system health assessment based on comprehensive analysis</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td><span class="badge bg-success">{0:N1}/100</span></td>', $analytics.HealthScore) | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Calculated from {0} metrics including error rates, anomalies, and patterns</td>', $analytics.Metrics.TotalEvents) | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        # 2. Executive Summary - Insights
        foreach ($insight in $analytics.Insights) {
            $htmlBuilder.AppendLine('                            <tr>') | Out-Null
            $htmlBuilder.AppendLine('                                <td><i class="fas fa-briefcase text-primary me-2"></i>Executive Summary</td>') | Out-Null
            $htmlBuilder.AppendLine('                                <td>Key Insight</td>') | Out-Null
            $htmlBuilder.AppendFormat('                                <td>{0}</td>', [System.Web.HttpUtility]::HtmlEncode($insight)) | Out-Null
            $htmlBuilder.AppendLine('                                <td><span class="badge bg-info">Informational</span></td>') | Out-Null
            $htmlBuilder.AppendLine('                                <td>Derived from statistical analysis of system behavior</td>') | Out-Null
            $htmlBuilder.AppendLine('                            </tr>') | Out-Null
        }

        # 3. Executive Summary - Recommendations
        foreach ($recommendation in $analytics.Recommendations) {
            $htmlBuilder.AppendLine('                            <tr>') | Out-Null
            $htmlBuilder.AppendLine('                                <td><i class="fas fa-briefcase text-primary me-2"></i>Executive Summary</td>') | Out-Null
            $htmlBuilder.AppendLine('                                <td>Recommendation</td>') | Out-Null
            $htmlBuilder.AppendFormat('                                <td>{0}</td>', [System.Web.HttpUtility]::HtmlEncode($recommendation)) | Out-Null
            $htmlBuilder.AppendLine('                                <td><span class="badge bg-warning">Action Required</span></td>') | Out-Null
            $htmlBuilder.AppendLine('                                <td>Expert system recommendation for optimization</td>') | Out-Null
            $htmlBuilder.AppendLine('                            </tr>') | Out-Null
        }

        # 4. Pattern Recognition - Detected Patterns
        foreach ($pattern in $patterns.DetectedPatterns) {
            $badgeClass = switch ($pattern.Severity) {
                'High' { 'danger' }
                'Medium' { 'warning' }
                default { 'info' }
            }
            $htmlBuilder.AppendLine('                            <tr>') | Out-Null
            $htmlBuilder.AppendLine('                                <td><i class="fas fa-brain text-success me-2"></i>Pattern Recognition</td>') | Out-Null
            $htmlBuilder.AppendFormat('                                <td>{0}</td>', [System.Web.HttpUtility]::HtmlEncode($pattern.Type)) | Out-Null
            $htmlBuilder.AppendFormat('                                <td>{0}</td>', [System.Web.HttpUtility]::HtmlEncode($pattern.Description)) | Out-Null
            $htmlBuilder.AppendFormat('                                <td><span class="badge bg-{0}">{1}</span></td>', $badgeClass, $pattern.Severity) | Out-Null
            $htmlBuilder.AppendLine('                                <td>Machine learning pattern detection result</td>') | Out-Null
            $htmlBuilder.AppendLine('                            </tr>') | Out-Null
        }

        # 5. Pattern Recognition - Process Clusters
        foreach ($cluster in $patterns.ProcessClusters) {
            $htmlBuilder.AppendLine('                            <tr>') | Out-Null
            $htmlBuilder.AppendLine('                                <td><i class="fas fa-brain text-success me-2"></i>Pattern Recognition</td>') | Out-Null
            $htmlBuilder.AppendLine('                                <td>Process Cluster</td>') | Out-Null
            $htmlBuilder.AppendFormat('                                <td>{0} Activity Cluster with {1} processes</td>', $cluster.Characteristics.Category, $cluster.Processes.Count) | Out-Null
            $htmlBuilder.AppendLine('                                <td><span class="badge bg-secondary">Cluster</span></td>') | Out-Null
            $htmlBuilder.AppendFormat('                                <td>Processes: {0}</td>', ($cluster.Processes -join ', ')) | Out-Null
            $htmlBuilder.AppendLine('                            </tr>') | Out-Null
        }

        # 6. Advanced Analytics - Metrics
        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-chart-line text-warning me-2"></i>Advanced Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Total Events</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Total number of events processed in analysis session</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td><span class="badge bg-primary">{0:N0}</span></td>', $analytics.Metrics.TotalEvents) | Out-Null
        $htmlBuilder.AppendLine('                                <td>Base metric for all calculations</td>') | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-chart-line text-warning me-2"></i>Advanced Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Error Rate</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Percentage of failed operations in the dataset</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td><span class="badge bg-danger">{0:P2}</span></td>', $analytics.Metrics.ErrorRate) | Out-Null
        $htmlBuilder.AppendLine('                                <td>Critical metric for system stability assessment</td>') | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-chart-line text-warning me-2"></i>Advanced Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Anomalies Detected</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Number of statistical anomalies identified through advanced analytics</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td><span class="badge bg-warning">{0}</span></td>', $analytics.Anomalies.Count) | Out-Null
        $htmlBuilder.AppendLine('                                <td>Anomalies indicate unusual system behavior requiring attention</td>') | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        # 7. Advanced Analytics - Anomaly Items
        if ($analytics.Anomalies.Count -gt 0) {
            foreach ($anomaly in $analytics.Anomalies.Items) {
                $htmlBuilder.AppendLine('                            <tr>') | Out-Null
                $htmlBuilder.AppendLine('                                <td><i class="fas fa-chart-line text-warning me-2"></i>Advanced Analytics</td>') | Out-Null
                $htmlBuilder.AppendLine('                                <td>Anomaly Detail</td>') | Out-Null
                $htmlBuilder.AppendFormat('                                <td>{0}</td>', [System.Web.HttpUtility]::HtmlEncode($anomaly)) | Out-Null
                $htmlBuilder.AppendLine('                                <td><span class="badge bg-danger">Anomaly</span></td>') | Out-Null
                $htmlBuilder.AppendLine('                                <td>Statistical outlier detected by ML algorithms</td>') | Out-Null
                $htmlBuilder.AppendLine('                            </tr>') | Out-Null
            }
        }

        # 8. Risk Assessment
        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-chart-line text-warning me-2"></i>Advanced Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Risk Assessment</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Overall system risk level based on comprehensive analysis</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td><span class="badge bg-danger">{0}</span></td>', $analytics.RiskAssessment.Level) | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Risk Score: {0}/100 - Requires immediate attention if High</td>', $analytics.RiskAssessment.Total) | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        # 9. ML Analytics - Temporal Analysis
        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-robot text-info me-2"></i>ML Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Temporal Trend</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Time-series analysis showing {0} trend direction</td>', $patterns.TemporalPatterns.TrendDirection) | Out-Null
        $htmlBuilder.AppendLine('                                <td><span class="badge bg-primary">Trend</span></td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Seasonality: {0} - ML prediction of future behavior</td>', $patterns.TemporalPatterns.Seasonality) | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        $htmlBuilder.AppendLine('                            <tr>') | Out-Null
        $htmlBuilder.AppendLine('                                <td><i class="fas fa-robot text-info me-2"></i>ML Analytics</td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Seasonality Pattern</td>') | Out-Null
        $htmlBuilder.AppendFormat('                                <td>Machine learning detected seasonality: {0}</td>', $patterns.TemporalPatterns.Seasonality) | Out-Null
        $htmlBuilder.AppendLine('                                <td><span class="badge bg-info">Pattern</span></td>') | Out-Null
        $htmlBuilder.AppendLine('                                <td>Recurring patterns identified through time-series analysis</td>') | Out-Null
        $htmlBuilder.AppendLine('                            </tr>') | Out-Null

        $htmlBuilder.AppendLine('                        </tbody>') | Out-Null
        $htmlBuilder.AppendLine('                    </table>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 2: EXECUTIVE SUMMARY (was Tab 1)
        $htmlBuilder.AppendLine('            <!-- Tab 2: Executive Summary -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade" id="tab-summary" role="tabpanel">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="row g-4">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="col-md-12">') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="table-container">') | Out-Null
        $htmlBuilder.AppendLine('                            <h3><i class="fas fa-briefcase me-2"></i>Executive Summary</h3>') | Out-Null
        $htmlBuilder.AppendFormat('                            <div class="alert alert-info"><strong>Health Score:</strong> {0:N1}/100</div>', $analytics.HealthScore) | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">Key Insights</h5>') | Out-Null
        $htmlBuilder.AppendLine('                            <ul class="list-group">') | Out-Null
        foreach ($insight in $analytics.Insights) {
            $htmlBuilder.AppendFormat('                                <li class="list-group-item">{0}</li>', [System.Web.HttpUtility]::HtmlEncode($insight)) | Out-Null
        }
        $htmlBuilder.AppendLine('                            </ul>') | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">Recommendations</h5>') | Out-Null
        $htmlBuilder.AppendLine('                            <ul class="list-group">') | Out-Null
        foreach ($recommendation in $analytics.Recommendations) {
            $htmlBuilder.AppendFormat('                                <li class="list-group-item">{0}</li>', [System.Web.HttpUtility]::HtmlEncode($recommendation)) | Out-Null
        }
        $htmlBuilder.AppendLine('                            </ul>') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 2: PATTERN RECOGNITION
        $htmlBuilder.AppendLine('            <!-- Tab 2: Pattern Recognition -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade" id="tab-patterns" role="tabpanel">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="row g-4">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="col-md-12">') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="table-container">') | Out-Null
        $htmlBuilder.AppendLine('                            <h3><i class="fas fa-brain me-2"></i>Pattern Recognition Analysis</h3>') | Out-Null
        $htmlBuilder.AppendFormat('                            <p class="lead">Detected {0} patterns across the dataset</p>', $patterns.DetectedPatterns.Count) | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">Detected Patterns</h5>') | Out-Null
        $htmlBuilder.AppendLine('                            <div class="row">') | Out-Null
        foreach ($pattern in $patterns.DetectedPatterns) {
            $badgeClass = switch ($pattern.Severity) {
                'High' { 'danger' }
                'Medium' { 'warning' }
                default { 'info' }
            }
            $htmlBuilder.AppendLine('                                <div class="col-md-6 mb-3">') | Out-Null
            $htmlBuilder.AppendLine('                                    <div class="alert alert-' + $badgeClass + '">') | Out-Null
            $htmlBuilder.AppendFormat('                                        <strong>{0}:</strong> {1}', [System.Web.HttpUtility]::HtmlEncode($pattern.Type), [System.Web.HttpUtility]::HtmlEncode($pattern.Description)) | Out-Null
            $htmlBuilder.AppendFormat('                                        <span class="badge bg-{0} float-end">{1}</span>', $badgeClass, $pattern.Severity) | Out-Null
            $htmlBuilder.AppendLine('                                    </div>') | Out-Null
            $htmlBuilder.AppendLine('                                </div>') | Out-Null
        }
        $htmlBuilder.AppendLine('                            </div>') | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">Process Clusters</h5>') | Out-Null
        $htmlBuilder.AppendLine('                            <div class="row">') | Out-Null
        foreach ($cluster in $patterns.ProcessClusters) {
            $htmlBuilder.AppendLine('                                <div class="col-md-4 mb-3">') | Out-Null
            $htmlBuilder.AppendLine('                                    <div class="metric-card">') | Out-Null
            $htmlBuilder.AppendFormat('                                        <div class="label">{0} Activity Processes</div>', $cluster.Characteristics.Category) | Out-Null
            $htmlBuilder.AppendFormat('                                        <div class="value">{0}</div>', $cluster.Processes.Count) | Out-Null
            $htmlBuilder.AppendLine('                                    </div>') | Out-Null
            $htmlBuilder.AppendLine('                                </div>') | Out-Null
        }
        $htmlBuilder.AppendLine('                            </div>') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 3: ADVANCED ANALYTICS
        $htmlBuilder.AppendLine('            <!-- Tab 3: Advanced Analytics -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade" id="tab-analytics" role="tabpanel">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="row g-4">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="col-md-12">') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="table-container">') | Out-Null
        $htmlBuilder.AppendLine('                            <h3><i class="fas fa-chart-line me-2"></i>Advanced Analytics</h3>') | Out-Null
        $htmlBuilder.AppendLine('                            <div class="row mb-4">') | Out-Null
        $htmlBuilder.AppendFormat('                                <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Total Events</div></div></div>', $analytics.Metrics.TotalEvents) | Out-Null
        $htmlBuilder.AppendFormat('                                <div class="col-md-3"><div class="metric-card"><div class="value">{0:P1}</div><div class="label">Error Rate</div></div></div>', $analytics.Metrics.ErrorRate) | Out-Null
        $htmlBuilder.AppendFormat('                                <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Anomalies Detected</div></div></div>', $analytics.Anomalies.Count) | Out-Null
        $htmlBuilder.AppendFormat('                                <div class="col-md-3"><div class="metric-card"><div class="value">{0}</div><div class="label">Risk Level</div></div></div>', $analytics.RiskAssessment.Level) | Out-Null
        $htmlBuilder.AppendLine('                            </div>') | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">Anomaly Detection Results</h5>') | Out-Null
        if ($analytics.Anomalies.Count -gt 0) {
            $htmlBuilder.AppendLine('                            <ul class="list-group">') | Out-Null
            foreach ($anomaly in $analytics.Anomalies.Items) {
                $htmlBuilder.AppendFormat('                                <li class="list-group-item">{0}</li>', [System.Web.HttpUtility]::HtmlEncode($anomaly)) | Out-Null
            }
            $htmlBuilder.AppendLine('                            </ul>') | Out-Null
        } else {
            $htmlBuilder.AppendLine('                            <div class="alert alert-success">No anomalies detected</div>') | Out-Null
        }
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 4: ML ANALYTICS
        $htmlBuilder.AppendLine('            <!-- Tab 4: ML Analytics -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade" id="tab-ml" role="tabpanel">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="row g-4">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="col-md-12">') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="table-container">') | Out-Null
        $htmlBuilder.AppendLine('                            <h3><i class="fas fa-robot me-2"></i>Machine Learning Analytics</h3>') | Out-Null
        $htmlBuilder.AppendLine('                            <p class="lead">Combined ML/AI insights from pattern recognition and advanced analytics engines</p>') | Out-Null
        $htmlBuilder.AppendLine('                            <h5 class="mt-4">ML Predictions & Insights</h5>') | Out-Null
        $htmlBuilder.AppendLine('                            <div class="row">') | Out-Null
        $htmlBuilder.AppendLine('                                <div class="col-md-6">') | Out-Null
        $htmlBuilder.AppendLine('                                    <div class="alert alert-primary">') | Out-Null
        $htmlBuilder.AppendLine('                                        <h6>Temporal Analysis</h6>') | Out-Null
        $htmlBuilder.AppendFormat('                                        <p><strong>Trend:</strong> {0}</p>', $patterns.TemporalPatterns.TrendDirection) | Out-Null
        $htmlBuilder.AppendFormat('                                        <p><strong>Seasonality:</strong> {0}</p>', $patterns.TemporalPatterns.Seasonality) | Out-Null
        $htmlBuilder.AppendLine('                                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                                </div>') | Out-Null
        $htmlBuilder.AppendLine('                                <div class="col-md-6">') | Out-Null
        $htmlBuilder.AppendLine('                                    <div class="alert alert-success">') | Out-Null
        $htmlBuilder.AppendLine('                                        <h6>Risk Assessment</h6>') | Out-Null
        $htmlBuilder.AppendFormat('                                        <p><strong>Overall Risk:</strong> {0}</p>', $analytics.RiskAssessment.Level) | Out-Null
        $htmlBuilder.AppendFormat('                                        <p><strong>Risk Score:</strong> {0}/100</p>', $analytics.RiskAssessment.Total) | Out-Null
        $htmlBuilder.AppendLine('                                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                                </div>') | Out-Null
        $htmlBuilder.AppendLine('                            </div>') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 5: EVENT DETAILS TABLE (with lazy loading)
        $htmlBuilder.AppendLine('            <!-- Tab 5: Event Details -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade lazy-load" id="tab-events" role="tabpanel" data-lazy="tables">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="table-container">') | Out-Null
        $htmlBuilder.AppendFormat('            <h4>Event Details (Showing first {0} records)</h4>', $ReportData.SampleEvents.Count) | Out-Null
        $htmlBuilder.AppendLine('            <table class="table table-striped">') | Out-Null
        $htmlBuilder.AppendLine('                <thead><tr><th>#</th>') | Out-Null

        # Dynamic table headers
        if ($ReportData.SampleEvents.Count -gt 0) {
            $firstEvent = $ReportData.SampleEvents[0]
            foreach ($prop in $firstEvent.PSObject.Properties.Name) {
                $htmlBuilder.AppendFormat('                    <th>{0}</th>', [System.Web.HttpUtility]::HtmlEncode($prop)) | Out-Null
            }
        }
        $htmlBuilder.AppendLine('                </thead>') | Out-Null
        $htmlBuilder.AppendLine('                <tbody>') | Out-Null

        # Table rows
        for ($i = 0; $i -lt $ReportData.SampleEvents.Count; $i++) {
            $event = $ReportData.SampleEvents[$i]
            $htmlBuilder.AppendFormat('                    <tr><td>{0}</td>', ($i + 1)) | Out-Null

            foreach ($prop in $event.PSObject.Properties.Name) {
                $value = [System.Web.HttpUtility]::HtmlEncode($event.$prop)
                $htmlBuilder.AppendFormat('                        <td>{0}</td>', $value) | Out-Null
            }
            $htmlBuilder.AppendLine('                    </tr>') | Out-Null
        }

        $htmlBuilder.AppendLine('                </tbody>') | Out-Null
        $htmlBuilder.AppendLine('            </table>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # TAB 6: CHARTS (with lazy loading)
        $htmlBuilder.AppendLine('            <!-- Tab 6: Charts -->') | Out-Null
        $htmlBuilder.AppendLine('            <div class="tab-pane fade lazy-load" id="tab-charts" role="tabpanel" data-lazy="charts">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="chart-container">') | Out-Null
        $htmlBuilder.AppendLine('                    <h3 class="mb-3"><i class="fas fa-chart-bar me-2"></i>Data Visualizations</h3>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="chart-thumbnail-container">') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="chart-thumbnail" data-bs-toggle="modal" data-bs-target="#processChartModal">') | Out-Null
        $htmlBuilder.AppendLine('                            <h5><i class="fas fa-chart-bar me-2"></i>Process Distribution <span class="chart-thumbnail-badge">Click to expand</span></h5>') | Out-Null
        $htmlBuilder.AppendFormat('                            <canvas id="processThumbnail" data-labels="{0}" data-data="{1}"></canvas>', $ReportData.ProcessChartData.Labels, $ReportData.ProcessChartData.Data) | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="chart-thumbnail" data-bs-toggle="modal" data-bs-target="#operationChartModal">') | Out-Null
        $htmlBuilder.AppendLine('                            <h5><i class="fas fa-chart-pie me-2"></i>Operation Distribution <span class="chart-thumbnail-badge">Click to expand</span></h5>') | Out-Null
        $htmlBuilder.AppendFormat('                            <canvas id="operationThumbnail" data-labels="{0}" data-data="{1}"></canvas>', $ReportData.OperationChartData.Labels, $ReportData.OperationChartData.Data) | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # CLOSE TAB CONTENT
        $htmlBuilder.AppendLine('        </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null

        # Chart Modals
        $htmlBuilder.AppendLine('        <!-- Process Chart Modal -->') | Out-Null
        $htmlBuilder.AppendLine('        <div class="modal fade" id="processChartModal" tabindex="-1">') | Out-Null
        $htmlBuilder.AppendLine('            <div class="modal-dialog modal-xl">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="modal-content">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-header">') | Out-Null
        $htmlBuilder.AppendLine('                        <h5 class="modal-title">Top Processes Distribution</h5>') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="btn-group btn-group-sm ms-3" role="group">') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-primary chart-type-btn" data-chart="process" data-type="bar">Bar</button>') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-primary chart-type-btn" data-chart="process" data-type="pie">Pie</button>') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-primary chart-type-btn" data-chart="process" data-type="doughnut">Doughnut</button>') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-body">') | Out-Null
        $htmlBuilder.AppendFormat('                        <canvas id="processChart" data-labels="{0}" data-data="{1}" style="max-height: 500px;"></canvas>', $ReportData.ProcessChartData.Labels, $ReportData.ProcessChartData.Data) | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-footer">') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn btn-secondary" id="downloadProcessChart"><i class="fas fa-download"></i> Download PNG</button>') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('        <!-- Operation Chart Modal -->') | Out-Null
        $htmlBuilder.AppendLine('        <div class="modal fade" id="operationChartModal" tabindex="-1">') | Out-Null
        $htmlBuilder.AppendLine('            <div class="modal-dialog modal-xl">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="modal-content">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-header">') | Out-Null
        $htmlBuilder.AppendLine('                        <h5 class="modal-title">Top Operations Distribution</h5>') | Out-Null
        $htmlBuilder.AppendLine('                        <div class="btn-group btn-group-sm ms-3" role="group">') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-success chart-type-btn" data-chart="operation" data-type="bar">Bar</button>') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-success chart-type-btn" data-chart="operation" data-type="pie">Pie</button>') | Out-Null
        $htmlBuilder.AppendLine('                            <button type="button" class="btn btn-outline-success chart-type-btn" data-chart="operation" data-type="doughnut">Doughnut</button>') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-body">') | Out-Null
        $htmlBuilder.AppendFormat('                        <canvas id="operationChart" data-labels="{0}" data-data="{1}" style="max-height: 500px;"></canvas>', $ReportData.OperationChartData.Labels, $ReportData.OperationChartData.Data) | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-footer">') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn btn-secondary" id="downloadOperationChart"><i class="fas fa-download"></i> Download PNG</button>') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null

        # Row Detail Modal
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('        <!-- Row Detail Modal -->') | Out-Null
        $htmlBuilder.AppendLine('        <div class="modal fade detail-modal" id="rowDetailModal" tabindex="-1">') | Out-Null
        $htmlBuilder.AppendLine('            <div class="modal-dialog modal-lg">') | Out-Null
        $htmlBuilder.AppendLine('                <div class="modal-content">') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-header">') | Out-Null
        $htmlBuilder.AppendLine('                        <h5 class="modal-title"><i class="fas fa-info-circle"></i> Event Details</h5>') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-body">') | Out-Null
        $htmlBuilder.AppendLine('                        <div id="detailContent" class="detail-content">') | Out-Null
        $htmlBuilder.AppendLine('                            <!-- Dynamic content will be inserted here -->') | Out-Null
        $htmlBuilder.AppendLine('                        </div>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                    <div class="modal-footer">') | Out-Null
        $htmlBuilder.AppendLine('                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>') | Out-Null
        $htmlBuilder.AppendLine('                    </div>') | Out-Null
        $htmlBuilder.AppendLine('                </div>') | Out-Null
        $htmlBuilder.AppendLine('            </div>') | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null

        # Footer
        $htmlBuilder.AppendLine('        <div class="footer" style="padding: 2rem; text-align: center; margin-top: 3rem;">') | Out-Null
        $htmlBuilder.AppendFormat('            <p><strong>Generated:</strong> {0} | <strong>Computer:</strong> {1}</p>', (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $env:COMPUTERNAME) | Out-Null
        $htmlBuilder.AppendLine('        </div>') | Out-Null
        $htmlBuilder.AppendLine('    </div>') | Out-Null

        # Scripts with full initialization
        $htmlBuilder.AppendLine('    <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- DataTables Core -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/1.13.8/js/jquery.dataTables.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/1.13.8/js/dataTables.bootstrap5.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- DataTables Extensions -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/buttons/2.4.2/js/dataTables.buttons.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/buttons/2.4.2/js/buttons.bootstrap5.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/buttons/2.4.2/js/buttons.html5.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.datatables.net/buttons/2.4.2/js/buttons.print.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- Export Dependencies -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/pdfmake.min.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdnjs.cloudflare.com/ajax/libs/pdfmake/0.2.7/vfs_fonts.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- Chart.js -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.3.0/dist/chart.umd.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- Search Enhancement Module -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="./Search-Enhancement.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <!-- Dynamic Chart Enhancement -->') | Out-Null
        $htmlBuilder.AppendLine('    <script src="./Add-DynamicChartScript.js"></script>') | Out-Null
        $htmlBuilder.AppendLine('    <script>') | Out-Null
        $htmlBuilder.AppendLine('        // Lazy Loading Observer for Performance Optimization') | Out-Null
        $htmlBuilder.AppendLine('        let chartsLoaded = false;') | Out-Null
        $htmlBuilder.AppendLine('        let tablesLoaded = false;') | Out-Null
        $htmlBuilder.AppendLine('        let dataTableInstance = null;') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('        const lazyLoadObserver = new IntersectionObserver((entries) => {') | Out-Null
        $htmlBuilder.AppendLine('            entries.forEach(entry => {') | Out-Null
        $htmlBuilder.AppendLine('                if (entry.isIntersecting) {') | Out-Null
        $htmlBuilder.AppendLine('                    const element = entry.target;') | Out-Null
        $htmlBuilder.AppendLine('                    const lazyType = element.dataset.lazy;') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                    if (lazyType === "charts" && !chartsLoaded) {') | Out-Null
        $htmlBuilder.AppendLine('                        loadChartThumbnails();') | Out-Null
        $htmlBuilder.AppendLine('                        chartsLoaded = true;') | Out-Null
        $htmlBuilder.AppendLine('                    } else if (lazyType === "tables" && !tablesLoaded) {') | Out-Null
        $htmlBuilder.AppendLine('                        loadDataTable();') | Out-Null
        $htmlBuilder.AppendLine('                        tablesLoaded = true;') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                    lazyLoadObserver.unobserve(element);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine('        }, { rootMargin: "50px" });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('        $(document).ready(function() {') | Out-Null
        $htmlBuilder.AppendLine('            // Initialize Detailed Analysis Table immediately') | Out-Null
        $htmlBuilder.AppendLine('            const detailedAnalysisTable = $("#detailedAnalysisTable").DataTable({') | Out-Null
        $htmlBuilder.AppendLine('                pageLength: 25,') | Out-Null
        $htmlBuilder.AppendLine('                lengthMenu: [[10, 25, 50, 100, -1], ["10 rows", "25 rows", "50 rows", "100 rows", "Show all"]],') | Out-Null
        $htmlBuilder.AppendLine('                order: [[0, "asc"]],') | Out-Null
        $htmlBuilder.AppendLine('                responsive: true,') | Out-Null
        $htmlBuilder.AppendLine('                dom: "<\"row mb-3\"<\"col-sm-12 col-md-6\"l><\"col-sm-12 col-md-6 text-end\"B>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12 col-md-6\"f><\"col-sm-12 col-md-6 text-end\"<\"clear-filters-detailed\">>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12\"tr>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12 col-md-5\"i><\"col-sm-12 col-md-7\"p>>",') | Out-Null
        $htmlBuilder.AppendLine('                buttons: [') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "excel",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-excel\"></i> Excel",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-success btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Detailed Analysis - " + new Date().toISOString().split("T")[0]') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "csv",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-csv\"></i> CSV",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-info btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Detailed Analysis - " + new Date().toISOString().split("T")[0]') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "pdf",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-pdf\"></i> PDF",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-danger btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Detailed Analysis",') | Out-Null
        $htmlBuilder.AppendLine('                        orientation: "landscape",') | Out-Null
        $htmlBuilder.AppendLine('                        pageSize: "LEGAL"') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "copy",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-copy\"></i> Copy",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-secondary btn-sm me-1"') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "print",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-print\"></i> Print",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-dark btn-sm"') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                ],') | Out-Null
        $htmlBuilder.AppendLine('                initComplete: function() {') | Out-Null
        $htmlBuilder.AppendLine('                    // Add column-specific checkbox filters for Category, Type, and Severity') | Out-Null
        $htmlBuilder.AppendLine('                    this.api().columns([0, 1, 3]).every(function(colIdx) {') | Out-Null
        $htmlBuilder.AppendLine('                        const column = this;') | Out-Null
        $htmlBuilder.AppendLine('                        const title = $(column.header()).text();') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        const filterContainer = $("<div style=\"position: relative;\"></div>").appendTo($(column.header()).empty());') | Out-Null
        $htmlBuilder.AppendLine('                        const filterBtn = $("<button class=\"column-filter-btn\" type=\"button\">" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<span class=\"filter-text\">" + title + "</span>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<i class=\"fas fa-chevron-down\"></i>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "</button>").appendTo(filterContainer);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        const dropdown = $("<div class=\"column-filter-dropdown\"></div>").appendTo(filterContainer);') | Out-Null
        $htmlBuilder.AppendLine('                        const searchBox = $("<div class=\"filter-search\"><input type=\"text\" placeholder=\"Search...\" class=\"filter-search-input\"></div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        const optionsContainer = $("<div class=\"filter-options\"></div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        const uniqueValues = [];') | Out-Null
        $htmlBuilder.AppendLine('                        column.data().unique().sort().each(function(d) {') | Out-Null
        $htmlBuilder.AppendLine('                            const textContent = $("<div>" + d + "</div>").text();') | Out-Null
        $htmlBuilder.AppendLine('                            if (textContent) uniqueValues.push(textContent);') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        uniqueValues.forEach(function(value) {') | Out-Null
        $htmlBuilder.AppendLine('                            const optionId = "filter_detailed_" + colIdx + "_" + value.replace(/[^a-zA-Z0-9]/g, "_");') | Out-Null
        $htmlBuilder.AppendLine('                            const option = $("<div class=\"filter-option\">" +') | Out-Null
        $htmlBuilder.AppendLine('                                "<input type=\"checkbox\" id=\"" + optionId + "\" value=\"" + value + "\" checked>" +') | Out-Null
        $htmlBuilder.AppendLine('                                "<label for=\"" + optionId + "\">" + value + "</label>" +') | Out-Null
        $htmlBuilder.AppendLine('                                "</div>");') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.append(option);') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        const actions = $("<div class=\"filter-actions\">" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<button class=\"select-all-btn\">Select All</button>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<button class=\"clear-btn\">Clear</button>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "</div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        filterBtn.on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            $(".column-filter-dropdown").not(dropdown).removeClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                            dropdown.toggleClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        searchBox.find("input").on("keyup", function() {') | Out-Null
        $htmlBuilder.AppendLine('                            const searchTerm = $(this).val().toLowerCase();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find(".filter-option").each(function() {') | Out-Null
        $htmlBuilder.AppendLine('                                const text = $(this).find("label").text().toLowerCase();') | Out-Null
        $htmlBuilder.AppendLine('                                $(this).toggle(text.indexOf(searchTerm) > -1);') | Out-Null
        $htmlBuilder.AppendLine('                            });') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        optionsContainer.on("change", "input[type=\"checkbox\"]", function() {') | Out-Null
        $htmlBuilder.AppendLine('                            const selectedValues = [];') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]:checked").each(function() {') | Out-Null
        $htmlBuilder.AppendLine('                                selectedValues.push($.fn.dataTable.util.escapeRegex($(this).val()));') | Out-Null
        $htmlBuilder.AppendLine('                            });') | Out-Null
        $htmlBuilder.AppendLine('                            ') | Out-Null
        $htmlBuilder.AppendLine('                            if (selectedValues.length === uniqueValues.length || selectedValues.length === 0) {') | Out-Null
        $htmlBuilder.AppendLine('                                column.search("").draw();') | Out-Null
        $htmlBuilder.AppendLine('                            } else {') | Out-Null
        $htmlBuilder.AppendLine('                                column.search(selectedValues.join("|"), true, false).draw();') | Out-Null
        $htmlBuilder.AppendLine('                            }') | Out-Null
        $htmlBuilder.AppendLine('                            ') | Out-Null
        $htmlBuilder.AppendLine('                            const checkedCount = optionsContainer.find("input[type=\"checkbox\"]:checked").length;') | Out-Null
        $htmlBuilder.AppendLine('                            if (checkedCount < uniqueValues.length) {') | Out-Null
        $htmlBuilder.AppendLine('                                filterBtn.find(".filter-text").html(title + " <span class=\"filter-count\">" + checkedCount + "</span>");') | Out-Null
        $htmlBuilder.AppendLine('                            } else {') | Out-Null
        $htmlBuilder.AppendLine('                                filterBtn.find(".filter-text").text(title);') | Out-Null
        $htmlBuilder.AppendLine('                            }') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        actions.find(".select-all-btn").on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]").prop("checked", true).first().trigger("change");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        actions.find(".clear-btn").on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]").prop("checked", false).first().trigger("change");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                    });') | Out-Null
        $htmlBuilder.AppendLine('                    ') | Out-Null
        $htmlBuilder.AppendLine('                    $(document).on("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                        $(".column-filter-dropdown").removeClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                    });') | Out-Null
        $htmlBuilder.AppendLine('                    ') | Out-Null
        $htmlBuilder.AppendLine('                    $("div.clear-filters-detailed").html("<button id=\"clearFiltersDetailedBtn\" class=\"btn btn-warning btn-sm\"><i class=\"fas fa-eraser\"></i> Clear All Filters</button>");') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Clear all filters for Detailed Analysis table') | Out-Null
        $htmlBuilder.AppendLine('            $(document).on("click", "#clearFiltersDetailedBtn", function() {') | Out-Null
        $htmlBuilder.AppendLine('                detailedAnalysisTable.columns([0, 1, 3]).every(function() {') | Out-Null
        $htmlBuilder.AppendLine('                    const header = $(this.header());') | Out-Null
        $htmlBuilder.AppendLine('                    header.find("input[type=\"checkbox\"]").prop("checked", true);') | Out-Null
        $htmlBuilder.AppendLine('                    this.search("");') | Out-Null
        $htmlBuilder.AppendLine('                    const title = header.find(".filter-text").text().split(" ")[0];') | Out-Null
        $htmlBuilder.AppendLine('                    header.find(".filter-text").text(title);') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('                detailedAnalysisTable.search("").draw();') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Row click handler for Detailed Analysis table') | Out-Null
        $htmlBuilder.AppendLine('            $("#detailedAnalysisTable tbody").on("click", "tr", function() {') | Out-Null
        $htmlBuilder.AppendLine('                const rowData = detailedAnalysisTable.row(this).data();') | Out-Null
        $htmlBuilder.AppendLine('                if (rowData) {') | Out-Null
        $htmlBuilder.AppendLine('                    let detailHtml = "";') | Out-Null
        $htmlBuilder.AppendLine('                    const columnNames = ["Category", "Type", "Description", "Severity/Score", "Details"];') | Out-Null
        $htmlBuilder.AppendLine('                    rowData.forEach(function(value, index) {') | Out-Null
        $htmlBuilder.AppendLine('                        const fieldName = columnNames[index] || "Field " + index;') | Out-Null
        $htmlBuilder.AppendLine('                        const fieldValue = $("<div>" + value + "</div>").text() || "(empty)";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "<div class=\"detail-item\">";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "  <div class=\"label\">" + fieldName + "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "  <div class=\"value\">" + fieldValue + "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                    });') | Out-Null
        $htmlBuilder.AppendLine('                    $("#detailContent").html(detailHtml);') | Out-Null
        $htmlBuilder.AppendLine('                    $("#rowDetailModal").modal("show");') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Observe lazy-load elements') | Out-Null
        $htmlBuilder.AppendLine('            document.querySelectorAll(".lazy-load").forEach(el => {') | Out-Null
        $htmlBuilder.AppendLine('                lazyLoadObserver.observe(el);') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Theme Management') | Out-Null
        $htmlBuilder.AppendLine('            const root = document.documentElement;') | Out-Null
        $htmlBuilder.AppendLine('            const themeToggle = document.getElementById("themeToggle");') | Out-Null
        $htmlBuilder.AppendLine('            const darkIcon = document.getElementById("darkIcon");') | Out-Null
        $htmlBuilder.AppendLine('            const lightIcon = document.getElementById("lightIcon");') | Out-Null
        $htmlBuilder.AppendLine('            const themeText = document.getElementById("themeText");') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Load saved theme or default to light') | Out-Null
        $htmlBuilder.AppendLine('            const savedTheme = localStorage.getItem("theme") || "light";') | Out-Null
        $htmlBuilder.AppendLine('            applyTheme(savedTheme);') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            function applyTheme(theme) {') | Out-Null
        $htmlBuilder.AppendLine('                root.setAttribute("data-theme", theme);') | Out-Null
        $htmlBuilder.AppendLine('                localStorage.setItem("theme", theme);') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                if (theme === "dark") {') | Out-Null
        $htmlBuilder.AppendLine('                    darkIcon.style.display = "none";') | Out-Null
        $htmlBuilder.AppendLine('                    lightIcon.style.display = "inline";') | Out-Null
        $htmlBuilder.AppendLine('                    themeText.textContent = "Light Mode";') | Out-Null
        $htmlBuilder.AppendLine('                } else {') | Out-Null
        $htmlBuilder.AppendLine('                    darkIcon.style.display = "inline";') | Out-Null
        $htmlBuilder.AppendLine('                    lightIcon.style.display = "none";') | Out-Null
        $htmlBuilder.AppendLine('                    themeText.textContent = "Dark Mode";') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Toggle theme on button click') | Out-Null
        $htmlBuilder.AppendLine('            themeToggle.addEventListener("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                const currentTheme = root.getAttribute("data-theme");') | Out-Null
        $htmlBuilder.AppendLine('                const newTheme = currentTheme === "light" ? "dark" : "light";') | Out-Null
        $htmlBuilder.AppendLine('                applyTheme(newTheme);') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Function to load DataTable (called by lazy loading)') | Out-Null
        $htmlBuilder.AppendLine('            window.loadDataTable = function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (dataTableInstance) return; // Already initialized') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                dataTableInstance = $(".table").DataTable({') | Out-Null
        $htmlBuilder.AppendLine('                pageLength: 25,') | Out-Null
        $htmlBuilder.AppendLine('                lengthMenu: [[10, 25, 50, 100, 500, -1], ["10 rows", "25 rows", "50 rows", "100 rows", "500 rows", "Show all"]],') | Out-Null
        $htmlBuilder.AppendLine('                order: [[0, "asc"]],') | Out-Null
        $htmlBuilder.AppendLine('                responsive: true,') | Out-Null
        $htmlBuilder.AppendLine('                dom: "<\"row mb-3\"<\"col-sm-12 col-md-6\"l><\"col-sm-12 col-md-6 text-end\"B>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12 col-md-6\"f><\"col-sm-12 col-md-6 text-end\"<\"clear-filters\">>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12\"tr>>" +') | Out-Null
        $htmlBuilder.AppendLine('                     "<\"row\"<\"col-sm-12 col-md-5\"i><\"col-sm-12 col-md-7\"p>>",') | Out-Null
        $htmlBuilder.AppendLine('                buttons: [') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "excel",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-excel\"></i> Excel",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-success btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Procmon Analysis - " + new Date().toISOString().split("T")[0],') | Out-Null
        $htmlBuilder.AppendLine('                        exportOptions: { orthogonal: "export" }') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "csv",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-csv\"></i> CSV",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-info btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Procmon Analysis - " + new Date().toISOString().split("T")[0],') | Out-Null
        $htmlBuilder.AppendLine('                        exportOptions: { orthogonal: "export" }') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "pdf",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-file-pdf\"></i> PDF",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-danger btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        title: "Procmon Analysis",') | Out-Null
        $htmlBuilder.AppendLine('                        orientation: "landscape",') | Out-Null
        $htmlBuilder.AppendLine('                        pageSize: "LEGAL",') | Out-Null
        $htmlBuilder.AppendLine('                        exportOptions: { orthogonal: "export" }') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "copy",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-copy\"></i> Copy",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-secondary btn-sm me-1",') | Out-Null
        $htmlBuilder.AppendLine('                        exportOptions: { orthogonal: "export" }') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    {') | Out-Null
        $htmlBuilder.AppendLine('                        extend: "print",') | Out-Null
        $htmlBuilder.AppendLine('                        text: "<i class=\"fas fa-print\"></i> Print",') | Out-Null
        $htmlBuilder.AppendLine('                        className: "btn btn-dark btn-sm",') | Out-Null
        $htmlBuilder.AppendLine('                        exportOptions: { orthogonal: "export" }') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                ],') | Out-Null
        $htmlBuilder.AppendLine('                initComplete: function() {') | Out-Null
        $htmlBuilder.AppendLine('                    // Add column-specific checkbox filter dropdowns') | Out-Null
        $htmlBuilder.AppendLine('                    this.api().columns().every(function(colIdx) {') | Out-Null
        $htmlBuilder.AppendLine('                        var column = this;') | Out-Null
        $htmlBuilder.AppendLine('                        var title = $(column.header()).text();') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Create filter container') | Out-Null
        $htmlBuilder.AppendLine('                        var filterContainer = $("<div style=\"position: relative;\"></div>").appendTo($(column.header()).empty());') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Create filter button') | Out-Null
        $htmlBuilder.AppendLine('                        var filterBtn = $("<button class=\"column-filter-btn\" type=\"button\">" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<span class=\"filter-text\">" + title + "</span>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<i class=\"fas fa-chevron-down\"></i>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "</button>").appendTo(filterContainer);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Create dropdown') | Out-Null
        $htmlBuilder.AppendLine('                        var dropdown = $("<div class=\"column-filter-dropdown\"></div>").appendTo(filterContainer);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Add search box') | Out-Null
        $htmlBuilder.AppendLine('                        var searchBox = $("<div class=\"filter-search\"><input type=\"text\" placeholder=\"Search...\" class=\"filter-search-input\"></div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Create options container') | Out-Null
        $htmlBuilder.AppendLine('                        var optionsContainer = $("<div class=\"filter-options\"></div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Get unique values sorted') | Out-Null
        $htmlBuilder.AppendLine('                        var uniqueValues = [];') | Out-Null
        $htmlBuilder.AppendLine('                        column.data().unique().sort().each(function(d) {') | Out-Null
        $htmlBuilder.AppendLine('                            if (d) uniqueValues.push(d);') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Add checkbox options') | Out-Null
        $htmlBuilder.AppendLine('                        uniqueValues.forEach(function(value) {') | Out-Null
        $htmlBuilder.AppendLine('                            var optionId = "filter_" + colIdx + "_" + value.replace(/[^a-zA-Z0-9]/g, "_");') | Out-Null
        $htmlBuilder.AppendLine('                            var option = $("<div class=\"filter-option\">" +') | Out-Null
        $htmlBuilder.AppendLine('                                "<input type=\"checkbox\" id=\"" + optionId + "\" value=\"" + value + "\" checked>" +') | Out-Null
        $htmlBuilder.AppendLine('                                "<label for=\"" + optionId + "\">" + value + "</label>" +') | Out-Null
        $htmlBuilder.AppendLine('                                "</div>");') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.append(option);') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Add action buttons') | Out-Null
        $htmlBuilder.AppendLine('                        var actions = $("<div class=\"filter-actions\">" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<button class=\"select-all-btn\">Select All</button>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "<button class=\"clear-btn\">Clear</button>" +') | Out-Null
        $htmlBuilder.AppendLine('                            "</div>").appendTo(dropdown);') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Toggle dropdown') | Out-Null
        $htmlBuilder.AppendLine('                        filterBtn.on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            $(".column-filter-dropdown").not(dropdown).removeClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                            dropdown.toggleClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Search functionality') | Out-Null
        $htmlBuilder.AppendLine('                        searchBox.find("input").on("keyup", function() {') | Out-Null
        $htmlBuilder.AppendLine('                            var searchTerm = $(this).val().toLowerCase();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find(".filter-option").each(function() {') | Out-Null
        $htmlBuilder.AppendLine('                                var text = $(this).find("label").text().toLowerCase();') | Out-Null
        $htmlBuilder.AppendLine('                                $(this).toggle(text.indexOf(searchTerm) > -1);') | Out-Null
        $htmlBuilder.AppendLine('                            });') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Checkbox change handler') | Out-Null
        $htmlBuilder.AppendLine('                        optionsContainer.on("change", "input[type=\"checkbox\"]", function() {') | Out-Null
        $htmlBuilder.AppendLine('                            var selectedValues = [];') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]:checked").each(function() {') | Out-Null
        $htmlBuilder.AppendLine('                                selectedValues.push($.fn.dataTable.util.escapeRegex($(this).val()));') | Out-Null
        $htmlBuilder.AppendLine('                            });') | Out-Null
        $htmlBuilder.AppendLine('                            ') | Out-Null
        $htmlBuilder.AppendLine('                            // Update filter') | Out-Null
        $htmlBuilder.AppendLine('                            if (selectedValues.length === uniqueValues.length || selectedValues.length === 0) {') | Out-Null
        $htmlBuilder.AppendLine('                                column.search("").draw();') | Out-Null
        $htmlBuilder.AppendLine('                            } else {') | Out-Null
        $htmlBuilder.AppendLine('                                column.search("^(" + selectedValues.join("|") + ")$", true, false).draw();') | Out-Null
        $htmlBuilder.AppendLine('                            }') | Out-Null
        $htmlBuilder.AppendLine('                            ') | Out-Null
        $htmlBuilder.AppendLine('                            // Update button text with count') | Out-Null
        $htmlBuilder.AppendLine('                            var checkedCount = optionsContainer.find("input[type=\"checkbox\"]:checked").length;') | Out-Null
        $htmlBuilder.AppendLine('                            if (checkedCount < uniqueValues.length) {') | Out-Null
        $htmlBuilder.AppendLine('                                filterBtn.find(".filter-text").html(title + " <span class=\"filter-count\">" + checkedCount + "</span>");') | Out-Null
        $htmlBuilder.AppendLine('                            } else {') | Out-Null
        $htmlBuilder.AppendLine('                                filterBtn.find(".filter-text").text(title);') | Out-Null
        $htmlBuilder.AppendLine('                            }') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Select All button') | Out-Null
        $htmlBuilder.AppendLine('                        actions.find(".select-all-btn").on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]").prop("checked", true).first().trigger("change");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                        ') | Out-Null
        $htmlBuilder.AppendLine('                        // Clear button') | Out-Null
        $htmlBuilder.AppendLine('                        actions.find(".clear-btn").on("click", function(e) {') | Out-Null
        $htmlBuilder.AppendLine('                            e.stopPropagation();') | Out-Null
        $htmlBuilder.AppendLine('                            optionsContainer.find("input[type=\"checkbox\"]").prop("checked", false).first().trigger("change");') | Out-Null
        $htmlBuilder.AppendLine('                        });') | Out-Null
        $htmlBuilder.AppendLine('                    });') | Out-Null
        $htmlBuilder.AppendLine('                    ') | Out-Null
        $htmlBuilder.AppendLine('                    // Close dropdowns when clicking outside') | Out-Null
        $htmlBuilder.AppendLine('                    $(document).on("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                        $(".column-filter-dropdown").removeClass("show");') | Out-Null
        $htmlBuilder.AppendLine('                    });') | Out-Null
        $htmlBuilder.AppendLine('                    ') | Out-Null
        $htmlBuilder.AppendLine('                    // Add "Clear All Filters" button') | Out-Null
        $htmlBuilder.AppendLine('                    $("div.clear-filters").html("<button id=\"clearFiltersBtn\" class=\"btn btn-warning btn-sm\"><i class=\"fas fa-eraser\"></i> Clear All Filters</button>");') | Out-Null
        $htmlBuilder.AppendLine('                    ') | Out-Null
        $htmlBuilder.AppendLine('                    // Initialize Search Enhancement Module') | Out-Null
        $htmlBuilder.AppendLine('                    if (window.SearchEnhancement) {') | Out-Null
        $htmlBuilder.AppendLine('                        SearchEnhancement.init(table);') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                ]') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('            };') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Clear all filters functionality') | Out-Null
        $htmlBuilder.AppendLine('            $(document).on("click", "#clearFiltersBtn", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (!dataTableInstance) return;') | Out-Null
        $htmlBuilder.AppendLine('                // Reset all column checkbox filters') | Out-Null
        $htmlBuilder.AppendLine('                dataTableInstance.columns().every(function() {') | Out-Null
        $htmlBuilder.AppendLine('                    var header = $(this.header());') | Out-Null
        $htmlBuilder.AppendLine('                    // Check all checkboxes in this column') | Out-Null
        $htmlBuilder.AppendLine('                    header.find("input[type=\"checkbox\"]").prop("checked", true);') | Out-Null
        $htmlBuilder.AppendLine('                    // Clear the column search') | Out-Null
        $htmlBuilder.AppendLine('                    this.search("");') | Out-Null
        $htmlBuilder.AppendLine('                    // Update button text to remove filter count') | Out-Null
        $htmlBuilder.AppendLine('                    var title = header.find(".filter-text").text().split(" ")[0];') | Out-Null
        $htmlBuilder.AppendLine('                    header.find(".filter-text").text(title);') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('                // Reset main search and redraw') | Out-Null
        $htmlBuilder.AppendLine('                dataTableInstance.search("").draw();') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Row click handler for detail view') | Out-Null
        $htmlBuilder.AppendLine('            $(".table tbody").on("click", "tr", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (!dataTableInstance) return;') | Out-Null
        $htmlBuilder.AppendLine('                var rowData = dataTableInstance.row(this).data();') | Out-Null
        $htmlBuilder.AppendLine('                if (rowData) {') | Out-Null
        $htmlBuilder.AppendLine('                    showRowDetails(rowData);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Function to display row details in modal') | Out-Null
        $htmlBuilder.AppendLine('            function showRowDetails(rowData) {') | Out-Null
        $htmlBuilder.AppendLine('                var detailHtml = "";') | Out-Null
        $htmlBuilder.AppendLine('                var columnNames = [];') | Out-Null
        $htmlBuilder.AppendLine('                $(".table thead th").each(function(index) {') | Out-Null
        $htmlBuilder.AppendLine('                    if (index > 0) {') | Out-Null
        $htmlBuilder.AppendLine('                        columnNames.push($(this).text().trim().split(" ")[0]);') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('                rowData.forEach(function(value, index) {') | Out-Null
        $htmlBuilder.AppendLine('                    if (index > 0) {') | Out-Null
        $htmlBuilder.AppendLine('                        var fieldName = columnNames[index - 1] || "Field " + index;') | Out-Null
        $htmlBuilder.AppendLine('                        var fieldValue = value || "(empty)";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "<div class=\"detail-item\">";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "  <div class=\"label\">" + fieldName + "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "  <div class=\"value\">" + fieldValue + "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                        detailHtml += "</div>";') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('                $("#detailContent").html(detailHtml);') | Out-Null
        $htmlBuilder.AppendLine('                $("#rowDetailModal").modal("show");') | Out-Null
        $htmlBuilder.AppendLine('            }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Professional Color Palette') | Out-Null
        $htmlBuilder.AppendLine('            const colorPalette = [') | Out-Null
        $htmlBuilder.AppendLine('                "rgba(102, 126, 234, 0.8)", "rgba(118, 75, 162, 0.8)", "rgba(40, 167, 69, 0.8)",') | Out-Null
        $htmlBuilder.AppendLine('                "rgba(255, 193, 7, 0.8)", "rgba(220, 53, 69, 0.8)", "rgba(23, 162, 184, 0.8)",') | Out-Null
        $htmlBuilder.AppendLine('                "rgba(108, 117, 125, 0.8)", "rgba(255, 99, 132, 0.8)", "rgba(54, 162, 235, 0.8)",') | Out-Null
        $htmlBuilder.AppendLine('                "rgba(255, 206, 86, 0.8)", "rgba(75, 192, 192, 0.8)", "rgba(153, 102, 255, 0.8)",') | Out-Null
        $htmlBuilder.AppendLine('                "rgba(255, 159, 64, 0.8)", "rgba(201, 203, 207, 0.8)", "rgba(255, 99, 71, 0.8)"') | Out-Null
        $htmlBuilder.AppendLine('            ];') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Chart instances') | Out-Null
        $htmlBuilder.AppendLine('            let processChartInstance = null;') | Out-Null
        $htmlBuilder.AppendLine('            let operationChartInstance = null;') | Out-Null
        $htmlBuilder.AppendLine('            let processThumbnailInstance = null;') | Out-Null
        $htmlBuilder.AppendLine('            let operationThumbnailInstance = null;') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Function to load chart thumbnails (called by lazy loading)') | Out-Null
        $htmlBuilder.AppendLine('            window.loadChartThumbnails = function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (processThumbnailInstance && operationThumbnailInstance) return; // Already loaded') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                // Initialize thumbnail charts') | Out-Null
        $htmlBuilder.AppendLine('                const processThumbnailCanvas = document.getElementById("processThumbnail");') | Out-Null
        $htmlBuilder.AppendLine('                if (processThumbnailCanvas && !processThumbnailInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const labels = processThumbnailCanvas.dataset.labels.split(",");') | Out-Null
        $htmlBuilder.AppendLine('                    const data = processThumbnailCanvas.dataset.data.split(",").map(Number);') | Out-Null
        $htmlBuilder.AppendLine('                    processThumbnailInstance = createChart(processThumbnailCanvas, labels, data, "bar", colorPalette[0]);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                const operationThumbnailCanvas = document.getElementById("operationThumbnail");') | Out-Null
        $htmlBuilder.AppendLine('                if (operationThumbnailCanvas && !operationThumbnailInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const labels = operationThumbnailCanvas.dataset.labels.split(",");') | Out-Null
        $htmlBuilder.AppendLine('                    const data = operationThumbnailCanvas.dataset.data.split(",").map(Number);') | Out-Null
        $htmlBuilder.AppendLine('                    operationThumbnailInstance = createChart(operationThumbnailCanvas, labels, data, "doughnut", colorPalette[1]);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            };') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Initialize charts when modals open') | Out-Null
        $htmlBuilder.AppendLine('            $("#processChartModal").on("shown.bs.modal", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (!processChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const canvas = document.getElementById("processChart");') | Out-Null
        $htmlBuilder.AppendLine('                    const labels = canvas.dataset.labels.split(",");') | Out-Null
        $htmlBuilder.AppendLine('                    const data = canvas.dataset.data.split(",").map(Number);') | Out-Null
        $htmlBuilder.AppendLine('                    processChartInstance = createChart(canvas, labels, data, "bar", colorPalette[0]);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            $("#operationChartModal").on("shown.bs.modal", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (!operationChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const canvas = document.getElementById("operationChart");') | Out-Null
        $htmlBuilder.AppendLine('                    const labels = canvas.dataset.labels.split(",");') | Out-Null
        $htmlBuilder.AppendLine('                    const data = canvas.dataset.data.split(",").map(Number);') | Out-Null
        $htmlBuilder.AppendLine('                    operationChartInstance = createChart(canvas, labels, data, "bar", colorPalette[1]);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Create chart function with professional config') | Out-Null
        $htmlBuilder.AppendLine('            function createChart(canvas, labels, data, type, primaryColor) {') | Out-Null
        $htmlBuilder.AppendLine('                const colors = type === "bar" ? data.map(() => primaryColor) : colorPalette.slice(0, data.length);') | Out-Null
        $htmlBuilder.AppendLine('                return new Chart(canvas, {') | Out-Null
        $htmlBuilder.AppendLine('                    type: type,') | Out-Null
        $htmlBuilder.AppendLine('                    data: {') | Out-Null
        $htmlBuilder.AppendLine('                        labels: labels,') | Out-Null
        $htmlBuilder.AppendLine('                        datasets: [{') | Out-Null
        $htmlBuilder.AppendLine('                            label: "Event Count",') | Out-Null
        $htmlBuilder.AppendLine('                            data: data,') | Out-Null
        $htmlBuilder.AppendLine('                            backgroundColor: colors,') | Out-Null
        $htmlBuilder.AppendLine('                            borderColor: colors.map(c => c.replace("0.8", "1")),') | Out-Null
        $htmlBuilder.AppendLine('                            borderWidth: 2,') | Out-Null
        $htmlBuilder.AppendLine('                            hoverOffset: 10') | Out-Null
        $htmlBuilder.AppendLine('                        }]') | Out-Null
        $htmlBuilder.AppendLine('                    },') | Out-Null
        $htmlBuilder.AppendLine('                    options: {') | Out-Null
        $htmlBuilder.AppendLine('                        responsive: true,') | Out-Null
        $htmlBuilder.AppendLine('                        maintainAspectRatio: false,') | Out-Null
        $htmlBuilder.AppendLine('                        animation: { duration: 1000, easing: "easeInOutQuart" },') | Out-Null
        $htmlBuilder.AppendLine('                        plugins: {') | Out-Null
        $htmlBuilder.AppendLine('                            legend: {') | Out-Null
        $htmlBuilder.AppendLine('                                display: type !== "bar",') | Out-Null
        $htmlBuilder.AppendLine('                                position: "top",') | Out-Null
        $htmlBuilder.AppendLine('                                onClick: (e, legendItem, legend) => {') | Out-Null
        $htmlBuilder.AppendLine('                                    const index = legendItem.index;') | Out-Null
        $htmlBuilder.AppendLine('                                    const chart = legend.chart;') | Out-Null
        $htmlBuilder.AppendLine('                                    const meta = chart.getDatasetMeta(0);') | Out-Null
        $htmlBuilder.AppendLine('                                    meta.data[index].hidden = !meta.data[index].hidden;') | Out-Null
        $htmlBuilder.AppendLine('                                    chart.update();') | Out-Null
        $htmlBuilder.AppendLine('                                }') | Out-Null
        $htmlBuilder.AppendLine('                            },') | Out-Null
        $htmlBuilder.AppendLine('                            tooltip: {') | Out-Null
        $htmlBuilder.AppendLine('                                callbacks: {') | Out-Null
        $htmlBuilder.AppendLine('                                    label: function(context) {') | Out-Null
        $htmlBuilder.AppendLine('                                        const label = context.label || "";') | Out-Null
        $htmlBuilder.AppendLine('                                        const value = context.parsed.x || context.parsed;') | Out-Null
        $htmlBuilder.AppendLine('                                        const total = context.dataset.data.reduce((a, b) => a + b, 0);') | Out-Null
        $htmlBuilder.AppendLine('                                        const percentage = ((value / total) * 100).toFixed(1);') | Out-Null
        $htmlBuilder.AppendLine('                                        return label + ": " + value.toLocaleString() + " (" + percentage + "%)";') | Out-Null
        $htmlBuilder.AppendLine('                                    }') | Out-Null
        $htmlBuilder.AppendLine('                                }') | Out-Null
        $htmlBuilder.AppendLine('                            }') | Out-Null
        $htmlBuilder.AppendLine('                        },') | Out-Null
        $htmlBuilder.AppendLine('                        indexAxis: ''y'',') | Out-Null
        $htmlBuilder.AppendLine('                        scales: type === "bar" ? {') | Out-Null
        $htmlBuilder.AppendLine('                            x: { beginAtZero: true, ticks: { precision: 0 } }') | Out-Null
        $htmlBuilder.AppendLine('                        } : {}') | Out-Null
        $htmlBuilder.AppendLine('                    }') | Out-Null
        $htmlBuilder.AppendLine('                });') | Out-Null
        $htmlBuilder.AppendLine('            }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Chart type switching') | Out-Null
        $htmlBuilder.AppendLine('            $(".chart-type-btn").on("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                const chartName = $(this).data("chart");') | Out-Null
        $htmlBuilder.AppendLine('                const newType = $(this).data("type");') | Out-Null
        $htmlBuilder.AppendLine('                const canvas = document.getElementById(chartName + "Chart");') | Out-Null
        $htmlBuilder.AppendLine('                const labels = canvas.dataset.labels.split(",");') | Out-Null
        $htmlBuilder.AppendLine('                const data = canvas.dataset.data.split(",").map(Number);') | Out-Null
        $htmlBuilder.AppendLine('                const primaryColor = chartName === "process" ? colorPalette[0] : colorPalette[1];') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                // Destroy existing chart') | Out-Null
        $htmlBuilder.AppendLine('                if (chartName === "process" && processChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    processChartInstance.destroy();') | Out-Null
        $htmlBuilder.AppendLine('                    processChartInstance = createChart(canvas, labels, data, newType, primaryColor);') | Out-Null
        $htmlBuilder.AppendLine('                } else if (chartName === "operation" && operationChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    operationChartInstance.destroy();') | Out-Null
        $htmlBuilder.AppendLine('                    operationChartInstance = createChart(canvas, labels, data, newType, primaryColor);') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('                // Update button states') | Out-Null
        $htmlBuilder.AppendLine('                $(this).siblings().removeClass("active");') | Out-Null
        $htmlBuilder.AppendLine('                $(this).addClass("active");') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            // Download chart as PNG') | Out-Null
        $htmlBuilder.AppendLine('            $("#downloadProcessChart").on("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (processChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const url = processChartInstance.toBase64Image();') | Out-Null
        $htmlBuilder.AppendLine('                    const a = document.createElement("a");') | Out-Null
        $htmlBuilder.AppendLine('                    a.href = url;') | Out-Null
        $htmlBuilder.AppendLine('                    a.download = "process-chart-" + new Date().toISOString().split("T")[0] + ".png";') | Out-Null
        $htmlBuilder.AppendLine('                    a.click();') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine() | Out-Null
        $htmlBuilder.AppendLine('            $("#downloadOperationChart").on("click", function() {') | Out-Null
        $htmlBuilder.AppendLine('                if (operationChartInstance) {') | Out-Null
        $htmlBuilder.AppendLine('                    const url = operationChartInstance.toBase64Image();') | Out-Null
        $htmlBuilder.AppendLine('                    const a = document.createElement("a");') | Out-Null
        $htmlBuilder.AppendLine('                    a.href = url;') | Out-Null
        $htmlBuilder.AppendLine('                    a.download = "operation-chart-" + new Date().toISOString().split("T")[0] + ".png";') | Out-Null
        $htmlBuilder.AppendLine('                    a.click();') | Out-Null
        $htmlBuilder.AppendLine('                }') | Out-Null
        $htmlBuilder.AppendLine('            });') | Out-Null
        $htmlBuilder.AppendLine('        });') | Out-Null
        $htmlBuilder.AppendLine('    </script>') | Out-Null

        $htmlBuilder.AppendLine("</body>") | Out-Null
        $htmlBuilder.AppendLine("</html>") | Out-Null

        return $htmlBuilder.ToString()
    }
    catch {
        Write-Error "Failed to generate HTML: $($_.Exception.Message)"
        return $null
    }
}

# Utility Functions
function Write-ReportLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # In a production environment, you might want to write to a log file
    switch ($Level) {
        "ERROR" { Write-Error $logMessage }
        "WARNING" { Write-Warning $logMessage }
        default { Write-Verbose $logMessage }
    }
}

function Test-ReportPrerequisites {
    [CmdletBinding()]
    param()

    $prerequisites = @(
        @{ Name = "PowerShell Version"; Test = { $PSVersionTable.PSVersion.Major -ge 5 } }
        @{ Name = "Output Directory"; Test = { Test-Path (Split-Path $OutputPath -Parent) } }
    )

    $missing = @()
    foreach ($prereq in $prerequisites) {
        if (-not (& $prereq.Test)) {
            $missing += $prereq.Name
        }
    }

    return $missing
}

# Function is now available for dot-sourcing
