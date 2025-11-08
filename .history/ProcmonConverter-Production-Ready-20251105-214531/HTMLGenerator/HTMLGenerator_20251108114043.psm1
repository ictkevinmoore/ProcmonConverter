<#
.SYNOPSIS
    Modular HTML Report Generator for Professional Reports

.DESCRIPTION
    Main module for generating professional HTML reports using templates and components.
    Provides a unified interface for creating modular, maintainable HTML reports.

.NOTES
    Author: AI Assistant
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

# Import required modules
using module ".\Core\TemplateEngine.psm1"
using module ".\Core\DataBinder.psm1"
using module ".\Components\SummaryComponent.psm1"

class HTMLGenerator {
    [TemplateEngine]$TemplateEngine
    [DataBinder]$DataBinder
    [hashtable]$Components
    [hashtable]$Config
    [string]$TemplatePath

    HTMLGenerator([string]$templatePath, [hashtable]$config = @{}) {
        $this.TemplatePath = $templatePath
        $this.Config = $this.MergeConfig($config)
        $this.InitializeCore()
        $this.InitializeComponents()
    }

    [void] InitializeCore() {
        # Initialize template engine
        $this.TemplateEngine = [TemplateEngine]::new($this.TemplatePath, $this.Config.EnableCache)

        # Initialize data binder
        $this.DataBinder = [DataBinder]::new($this.Config.StrictMode)
    }

    [void] InitializeComponents() {
        $this.Components = @{}

        # Initialize summary component
        $this.Components['Summary'] = New-SummaryComponent -TemplateEngine $this.TemplateEngine -Config $this.Config.SummaryConfig

        # Add more components here as they are created
        # $this.Components['Analytics'] = New-AnalyticsComponent -TemplateEngine $this.TemplateEngine
        # $this.Components['Charts'] = New-ChartsComponent -TemplateEngine $this.TemplateEngine
    }

    [hashtable] MergeConfig([hashtable]$userConfig) {
        $defaultConfig = @{
            EnableCache = $true
            StrictMode = $false
            MaxSampleSize = 5000
            TopItemsCount = 15
            Theme = 'auto'
            OutputFormat = 'html'
            SummaryConfig = @{
                EnableHealthScore = $true
                MaxInsights = 10
                MaxRecommendations = 10
            }
            ChartConfig = @{
                Width = 400
                Height = 300
                ColorScheme = 'professional'
                Animation = $true
            }
        }

        # Deep merge user config with defaults
        return $this.MergeHashtables($defaultConfig, $userConfig)
    }

    [hashtable] MergeHashtables([hashtable]$base, [hashtable]$override) {
        $result = $base.Clone()

        foreach ($key in $override.Keys) {
            if ($result.ContainsKey($key) -and $result[$key] -is [hashtable] -and $override[$key] -is [hashtable]) {
                $result[$key] = $this.MergeHashtables($result[$key], $override[$key])
            }
            else {
                $result[$key] = $override[$key]
            }
        }

        return $result
    }

    [hashtable] GenerateReport([hashtable]$rawData) {
        try {
            Write-Verbose "Starting report generation..."

            # Convert raw data to binding format
            $bindingData = ConvertTo-DataBindingFormat -DataObject $rawData -SessionInfo $rawData.SessionInfo -MaxSampleSize $this.Config.MaxSampleSize -TopItemsCount $this.Config.TopItemsCount

            # Bind data with validation
            $boundData = $this.DataBinder.BindReportData($bindingData)

            # Generate report sections
            $reportSections = $this.GenerateReportSections($boundData)

            # Assemble final report
            $finalReport = $this.AssembleFinalReport($boundData, $reportSections)

            Write-Verbose "Report generation completed successfully"

            return @{
                Success = $true
                HTML = $finalReport
                Data = $boundData
                Sections = $reportSections
                Metadata = @{
                    GeneratedAt = Get-Date
                    TemplateVersion = "1.0.0"
                    ComponentCount = $this.Components.Count
                }
            }
        }
        catch {
            Write-Error "Report generation failed: $($_.Exception.Message)"
            return @{
                Success = $false
                Error = $_.Exception.Message
                HTML = $this.GenerateErrorReport($_.Exception.Message)
            }
        }
    }

    [hashtable] GenerateReportSections([hashtable]$data) {
        $sections = @{}

        # Generate summary section
        if ($this.Components.ContainsKey('Summary')) {
            $sections['Summary'] = $this.Components['Summary'].Render($data)
        }

        # Generate analytics section
        $sections['Analytics'] = $this.GenerateAnalyticsSection($data)

        # Generate charts section
        $sections['Charts'] = $this.GenerateChartsSection($data)

        # Generate events table section
        $sections['Events'] = $this.GenerateEventsSection($data)

        return $sections
    }

    [string] GenerateAnalyticsSection([hashtable]$data) {
        # For now, return a basic analytics section
        # This will be enhanced when the AnalyticsComponent is created
        return @"
<div class="row g-4">
    <div class="col-md-12">
        <div class="table-container">
            <h3><i class="fas fa-chart-line me-2"></i>Advanced Analytics</h3>
            <div class="row mb-4">
                <div class="col-md-3"><div class="metric-card"><div class="value">$($data.Summary.TotalRecords)</div><div class="label">Total Events</div></div></div>
                <div class="col-md-3"><div class="metric-card"><div class="value">$($data.Summary.UniqueProcesses)</div><div class="label">Unique Processes</div></div></div>
                <div class="col-md-3"><div class="metric-card"><div class="value">$($data.Summary.OperationTypes)</div><div class="label">Operation Types</div></div></div>
                <div class="col-md-3"><div class="metric-card"><div class="value">$($data.Insights.AverageEventsPerProcess)</div><div class="label">Avg Events/Process</div></div></div>
            </div>
        </div>
    </div>
</div>
"@
    }

    [string] GenerateChartsSection([hashtable]$data) {
        return @"
<div class="chart-container">
    <h3 class="mb-3"><i class="fas fa-chart-bar me-2"></i>Data Visualizations</h3>
    <div class="chart-thumbnail-container">
        <div class="chart-thumbnail">
            <h5><i class="fas fa-chart-bar me-2"></i>Process Distribution</h5>
            <canvas id="processThumbnail" data-labels="$($data.ProcessChartData.Labels)" data-data="$($data.ProcessChartData.Data)"></canvas>
        </div>
        <div class="chart-thumbnail">
            <h5><i class="fas fa-chart-pie me-2"></i>Operation Distribution</h5>
            <canvas id="operationThumbnail" data-labels="$($data.OperationChartData.Labels)" data-data="$($data.OperationChartData.Data)"></canvas>
        </div>
    </div>
</div>
"@
    }

    [string] GenerateEventsSection([hashtable]$data) {
        $tableHeaders = "<th>#</th><th>Time</th><th>Process</th><th>Operation</th><th>Path</th><th>Result</th>"
        $tableRows = ""

        for ($i = 0; $i -lt $data.SampleEvents.Count; $i++) {
            $event = $data.SampleEvents[$i]
            $tableRows += "<tr><td>$($i + 1)</td><td>$($event.Time)</td><td>$($event.ProcessName)</td><td>$($event.Operation)</td><td>$($event.Path)</td><td>$($event.Result)</td></tr>"
        }

        return @"
<div class="table-container">
    <h4>Event Details (Showing first $($data.SampleEvents.Count) records)</h4>
    <table class="table table-striped">
        <thead><tr>$tableHeaders</tr></thead>
        <tbody>$tableRows</tbody>
    </table>
</div>
"@
    }

    [string] AssembleFinalReport([hashtable]$data, [hashtable]$sections) {
        # Prepare main template data
        $templateData = @{
            SessionId = $data.SessionInfo.SessionId
            TotalRecords = $data.Summary.TotalRecords.ToString("N0")
            FilesProcessed = $data.Summary.FilesProcessed
            UniqueProcesses = $data.Summary.UniqueProcesses
            OperationTypes = $data.Summary.OperationTypes
            GeneratedDate = $data.GeneratedDate
            ComputerName = $data.ComputerName
            TabContent = $this.GenerateTabContent($sections)
        }

        # Render main template
        return $this.TemplateEngine.Render('ReportTemplate', $templateData)
    }

    [string] GenerateTabContent([hashtable]$sections) {
        # For now, use the existing TabContent template structure
        # This will be enhanced to use dynamic tab generation
        $tabContentData = @{
            Insights = $sections['Summary']
            Patterns = "<div class='alert alert-info'>Pattern recognition analysis will be available in future versions</div>"
            Analytics = $sections['Analytics']
            ML = "<div class='alert alert-info'>ML Analytics will be available in future versions</div>"
            Events = $sections['Events']
            Charts = $sections['Charts']
            ProcessLabels = "Process A,Process B,Process C"
            ProcessData = "100,200,150"
            OperationLabels = "Read,Write,Execute"
            OperationData = "300,150,75"
            SampleSize = "5000"
        }

        return $this.TemplateEngine.Render('TabContent', $tabContentData)
    }

    [string] GenerateErrorReport([string]$errorMessage) {
        return @"
<!DOCTYPE html>
<html>
<head>
    <title>Report Generation Error</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <div class="alert alert-danger">
            <h4>Report Generation Failed</h4>
            <p>$errorMessage</p>
        </div>
    </div>
</body>
</html>
"@
    }

    [void] SaveReport([string]$html, [string]$outputPath) {
        try {
            $html | Out-File -FilePath $outputPath -Encoding UTF8 -Force
            Write-Verbose "Report saved to: $outputPath"
        }
        catch {
            throw "Failed to save report: $($_.Exception.Message)"
        }
    }

    [void] AddComponent([string]$name, [object]$component) {
        $this.Components[$name] = $component
    }

    [object] GetComponent([string]$name) {
        return $this.Components[$name]
    }
}

# Main function to create and use the HTML generator
function New-HTMLReport {
    <#
    .SYNOPSIS
        Generates a professional HTML report using the modular system

    .DESCRIPTION
        Creates a comprehensive HTML report from Procmon data using templates and components.

    .PARAMETER DataObject
        The processed data object containing events and summaries

    .PARAMETER SessionInfo
        Session information (Version, SessionId, etc.)

    .PARAMETER OutputPath
        Path where the HTML report will be saved

    .PARAMETER TemplatePath
        Path to the template directory (defaults to .\Templates)

    .PARAMETER Config
        Optional configuration hashtable for customizing report generation

    .EXAMPLE
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
        }

        New-HTMLReport -DataObject $data -SessionInfo $session -OutputPath ".\report.html"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [string]$TemplatePath = ".\Templates",

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    try {
        # Ensure template path exists
        if (-not (Test-Path $TemplatePath)) {
            throw "Template path not found: $TemplatePath"
        }

        # Create generator instance
        $generator = [HTMLGenerator]::new($TemplatePath, $Config)

        # Add session info to data object
        $DataObject['SessionInfo'] = $SessionInfo

        # Generate report
        $result = $generator.GenerateReport($DataObject)

        if ($result.Success) {
            # Save report
            $generator.SaveReport($result.HTML, $OutputPath)

            Write-Host "Report generated successfully: $OutputPath" -ForegroundColor Green
            return @{
                Success = $true
                ReportPath = $OutputPath
                DataSummary = $result.Data.Summary
            }
        }
        else {
            throw $result.Error
        }
    }
    catch {
        Write-Error "Report generation failed: $($_.Exception.Message)"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function New-HTMLReport
