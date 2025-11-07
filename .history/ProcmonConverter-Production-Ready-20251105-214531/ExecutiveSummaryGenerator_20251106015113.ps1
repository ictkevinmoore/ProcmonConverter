#Requires -Version 5.1

<#
.SYNOPSIS
    Executive Summary Generator with Professional HTML Dashboard

.DESCRIPTION
    Generates comprehensive executive summaries and interactive HTML dashboards
    with Bootstrap 5, Chart.js visualizations, and natural language insights.
    Integrates with AdvancedAnalyticsEngine and PatternRecognitionEngine.

.NOTES
    Version: 1.0
    Author: Enhanced Analysis Suite

.EXAMPLE
    $generator = [ExecutiveSummaryGenerator]::new()
    $html = $generator.GenerateReport($analytics, $patterns, $processedData)
    $generator.SaveReport($html, "ProcmonAnalysis-Report.html")
#>

using namespace System.Collections.Generic
using namespace System.Text
using namespace System.IO

#region Report Configuration

class ReportConfiguration {
    [string]$Title = "Procmon Professional Analysis Report"
    [string]$CompanyName = "System Analysis Team"
    [bool]$IncludeCharts = $true
    [bool]$IncludeDetailedTables = $true
    [bool]$IncludeExecutiveSummary = $true
    [bool]$IncludeRecommendations = $true
    [bool]$DarkMode = $false
    [string]$PrimaryColor = "#0d6efd"
    [string]$SuccessColor = "#198754"
    [string]$WarningColor = "#ffc107"
    [string]$DangerColor = "#dc3545"
    [string]$InfoColor = "#0dcaf0"

    ReportConfiguration() {
        # Default constructor
    }
}

#endregion

#region Executive Summary Generator

class ExecutiveSummaryGenerator {
    [ReportConfiguration]$Config
    [hashtable]$Templates

    ExecutiveSummaryGenerator() {
        $this.Config = [ReportConfiguration]::new()
        $this.Templates = @{}
        $this.InitializeTemplates()
    }

    ExecutiveSummaryGenerator([ReportConfiguration]$config) {
        $this.Config = $config
        $this.Templates = @{}
        $this.InitializeTemplates()
    }

    # Initialize HTML templates
    hidden [void] InitializeTemplates() {
        $this.Templates['head'] = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{TITLE}}</title>

    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">

    <!-- DataTables CSS -->
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.7/css/dataTables.bootstrap5.min.css">

    <style>
        :root {
            --primary-color: {{PRIMARY_COLOR}};
            --success-color: {{SUCCESS_COLOR}};
            --warning-color: {{WARNING_COLOR}};
            --danger-color: {{DANGER_COLOR}};
            --info-color: {{INFO_COLOR}};
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            padding-top: 20px;
            padding-bottom: 40px;
        }

        .report-header {
            background: linear-gradient(135deg, var(--primary-color) 0%, #0a58ca 100%);
            color: white;
            padding: 40px 0;
            margin-bottom: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        .metric-card {
            transition: transform 0.2s, box-shadow 0.2s;
            border: none;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }

        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 16px rgba(0,0,0,0.15);
        }

        .metric-value {
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .metric-label {
            font-size: 0.9rem;
            color: #6c757d;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        .health-score-widget {
            position: relative;
            width: 200px;
            height: 200px;
            margin: 0 auto;
        }

        .section-title {
            border-left: 4px solid var(--primary-color);
            padding-left: 15px;
            margin: 30px 0 20px 0;
            font-weight: 600;
        }

        .insight-card {
            background: white;
            border-left: 4px solid var(--info-color);
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .recommendation-card {
            background: white;
            border-left: 4px solid var(--warning-color);
            padding: 20px;
            margin-bottom: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }

        .pattern-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 500;
            margin: 5px;
        }

        .severity-high {
            background-color: #fee;
            color: #d63384;
            border: 1px solid #d63384;
        }

        .severity-medium {
            background-color: #fff3cd;
            color: #997404;
            border: 1px solid #997404;
        }

        .severity-low {
            background-color: #d1e7dd;
            color: #0f5132;
            border: 1px solid #0f5132;
        }

        .chart-container {
            position: relative;
            height: 400px;
            margin: 20px 0;
        }

        .risk-matrix {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin: 20px 0;
        }

        .risk-cell {
            padding: 20px;
            text-align: center;
            border-radius: 8px;
            color: white;
            font-weight: 600;
            min-height: 100px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .risk-critical { background-color: #dc3545; }
        .risk-high { background-color: #fd7e14; }
        .risk-medium { background-color: #ffc107; color: #333; }
        .risk-low { background-color: #20c997; }

        .export-buttons {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
        }

        @media print {
            .export-buttons, .no-print { display: none; }
            body { background-color: white; }
            .metric-card { break-inside: avoid; }
        }

        .process-cluster-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.08);
        }

        .executive-summary {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }

        .timeline-item {
            border-left: 3px solid var(--primary-color);
            padding-left: 20px;
            margin-bottom: 20px;
            padding-bottom: 20px;
        }
    </style>
</head>
<body>
'@

        $this.Templates['header'] = @'
    <div class="container-fluid">
        <div class="export-buttons no-print">
            <button class="btn btn-light btn-sm me-2" onclick="window.print()">
                <i class="fas fa-print"></i> Print
            </button>
            <button class="btn btn-light btn-sm" onclick="exportToExcel()">
                <i class="fas fa-file-excel"></i> Export
            </button>
        </div>

        <div class="report-header">
            <div class="container">
                <h1 class="display-4"><i class="fas fa-chart-line me-3"></i>{{TITLE}}</h1>
                <p class="lead">{{SUBTITLE}}</p>
                <p class="mb-0"><i class="far fa-calendar-alt"></i> Generated: {{TIMESTAMP}}</p>
            </div>
        </div>
'@

        $this.Templates['footer'] = @'
    </div>

    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>

    <!-- Bootstrap 5 JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>

    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.7/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.7/js/dataTables.bootstrap5.min.js"></script>

    <!-- Export Libraries -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js"></script>

    <script>
        // Initialize DataTables
        $(document).ready(function() {
            $('table.data-table').DataTable({
                pageLength: 25,
                order: [[1, 'desc']],
                responsive: true,
                dom: 'Bfrtip',
                language: {
                    search: "Filter:",
                    searchPlaceholder: "Search all columns..."
                }
            });
        });

        // Export to Excel function
        function exportToExcel() {
            const wb = XLSX.utils.book_new();

            // Export each table
            document.querySelectorAll('table.data-table').forEach((table, index) => {
                const ws = XLSX.utils.table_to_sheet(table);
                XLSX.utils.book_append_sheet(wb, ws, `Sheet${index + 1}`);
            });

            XLSX.writeFile(wb, 'ProcmonAnalysis_' + new Date().toISOString().slice(0,10) + '.xlsx');
        }

        // Smooth scroll
        document.querySelectorAll('a[href^="#"]').forEach(anchor => {
            anchor.addEventListener('click', function (e) {
                e.preventDefault();
                const target = document.querySelector(this.getAttribute('href'));
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        });
    </script>

    {{CHART_SCRIPTS}}
</body>
</html>
'@
    }

    # Generate complete HTML report
    [string] GenerateReport([hashtable]$analytics, [hashtable]$patterns, [hashtable]$processedData) {
        $sb = [StringBuilder]::new()

        # Build head section
        $head = $this.Templates['head']
        $head = $head -replace '{{TITLE}}', $this.Config.Title
        $head = $head -replace '{{PRIMARY_COLOR}}', $this.Config.PrimaryColor
        $head = $head -replace '{{SUCCESS_COLOR}}', $this.Config.SuccessColor
        $head = $head -replace '{{WARNING_COLOR}}', $this.Config.WarningColor
        $head = $head -replace '{{DANGER_COLOR}}', $this.Config.DangerColor
        $head = $head -replace '{{INFO_COLOR}}', $this.Config.InfoColor
        $sb.AppendLine($head) | Out-Null

        # Build header
        $header = $this.Templates['header']
        $header = $header -replace '{{TITLE}}', $this.Config.Title
        $header = $header -replace '{{SUBTITLE}}', "Comprehensive System Activity Analysis"
        $header = $header -replace '{{TIMESTAMP}}', (Get-Date -Format "MMMM dd, yyyy HH:mm:ss")
        $sb.AppendLine($header) | Out-Null

        # Executive Summary Section
        if ($this.Config.IncludeExecutiveSummary) {
            $sb.AppendLine($this.GenerateExecutiveSummary($analytics, $patterns)) | Out-Null
        }

        # Key Metrics Dashboard
        $sb.AppendLine($this.GenerateMetricsDashboard($analytics, $processedData)) | Out-Null

        # Health Score Widget
        $sb.AppendLine($this.GenerateHealthScoreSection($analytics)) | Out-Null

        # Risk Assessment
        $sb.AppendLine($this.GenerateRiskAssessmentSection($analytics)) | Out-Null

        # Pattern Analysis
        if ($patterns) {
            $sb.AppendLine($this.GeneratePatternAnalysisSection($patterns)) | Out-Null
        }

        # Charts Section
        if ($this.Config.IncludeCharts) {
            $sb.AppendLine($this.GenerateChartsSection($analytics, $processedData)) | Out-Null
        }

        # Detailed Tables
        if ($this.Config.IncludeDetailedTables) {
            $sb.AppendLine($this.GenerateDetailedTablesSection($analytics, $processedData)) | Out-Null
        }

        # Insights and Recommendations
        $sb.AppendLine($this.GenerateInsightsSection($analytics)) | Out-Null

        if ($this.Config.IncludeRecommendations) {
            $sb.AppendLine($this.GenerateRecommendationsSection($analytics)) | Out-Null
        }

        # Build footer with chart scripts
        $chartScripts = $this.GenerateChartScripts($analytics, $processedData)
        $footer = $this.Templates['footer'] -replace '{{CHART_SCRIPTS}}', $chartScripts
        $sb.AppendLine($footer) | Out-Null

        return $sb.ToString()
    }

    # Generate Executive Summary
    hidden [string] GenerateExecutiveSummary([hashtable]$analytics, [hashtable]$patterns) {
        $summary = New-Object StringBuilder

        $summary.AppendLine('<div class="container"><div class="executive-summary">') | Out-Null
        $summary.AppendLine('<h2 class="section-title"><i class="fas fa-file-alt me-2"></i>Executive Summary</h2>') | Out-Null

        # Generate natural language summary
        $totalEvents = if ($analytics.Metrics.TotalEvents) { $analytics.Metrics.TotalEvents } else { 0 }
        $errorRate = if ($analytics.Metrics.ErrorRate) { [Math]::Round($analytics.Metrics.ErrorRate * 100, 2) } else { 0 }
        $healthScore = if ($analytics.HealthScore) { [Math]::Round($analytics.HealthScore, 1) } else { 0 }
        $riskLevel = if ($analytics.RiskAssessment.Level) { $analytics.RiskAssessment.Level } else { "Unknown" }

        $summary.AppendLine("<p class='lead'>This report analyzes <strong>$($totalEvents.ToString('N0'))</strong> system events captured during the monitoring period.</p>") | Out-Null

        # System health assessment
        $healthStatus = if ($healthScore -ge 80) { "excellent" }
                       elseif ($healthScore -ge 60) { "good" }
                       elseif ($healthScore -ge 40) { "fair" }
                       else { "poor" }

        $summary.AppendLine("<h5>System Health Assessment</h5>") | Out-Null
        $summary.AppendLine("<p>The system demonstrates <strong>$healthStatus</strong> overall health with a score of <strong>$healthScore/100</strong>. ") | Out-Null

        if ($errorRate -gt 10) {
            $summary.AppendLine("The elevated error rate of <strong>$errorRate%</strong> indicates significant operational issues requiring immediate attention.") | Out-Null
        }
        elseif ($errorRate -gt 5) {
            $summary.AppendLine("The error rate of <strong>$errorRate%</strong> suggests moderate operational challenges that should be addressed.") | Out-Null
        }
        else {
            $summary.AppendLine("The low error rate of <strong>$errorRate%</strong> indicates stable system operations.") | Out-Null
        }
        $summary.AppendLine("</p>") | Out-Null

        # Risk assessment summary
        $summary.AppendLine("<h5>Risk Profile</h5>") | Out-Null
        $summary.AppendLine("<p>The overall risk level is classified as <strong class='text-$($this.GetRiskColorClass($riskLevel))'>$riskLevel</strong>. ") | Out-Null

        if ($riskLevel -in @("Critical", "High")) {
            $summary.AppendLine("This elevated risk profile demands immediate investigation and remediation to prevent potential system instability or security breaches.") | Out-Null
        }
        elseif ($riskLevel -eq "Medium") {
            $summary.AppendLine("While manageable, this risk level warrants monitoring and proactive measures to prevent escalation.") | Out-Null
        }
        else {
            $summary.AppendLine("The current risk profile is within acceptable parameters for normal operations.") | Out-Null
        }
        $summary.AppendLine("</p>") | Out-Null

        # Pattern insights
        if ($patterns -and $patterns.DetectedPatterns.Count -gt 0) {
            $summary.AppendLine("<h5>Pattern Analysis</h5>") | Out-Null
            $summary.AppendLine("<p>Advanced pattern recognition identified <strong>$($patterns.DetectedPatterns.Count)</strong> significant behavioral patterns. ") | Out-Null

            $highSeverityPatterns = ($patterns.DetectedPatterns | Where-Object { $_.Severity -eq "High" }).Count
            if ($highSeverityPatterns -gt 0) {
                $summary.AppendLine("Of particular concern are <strong>$highSeverityPatterns</strong> high-severity patterns that require immediate review.") | Out-Null
            }
            else {
                $summary.AppendLine("Most detected patterns are within expected operational boundaries.") | Out-Null
            }
            $summary.AppendLine("</p>") | Out-Null
        }

        # Key findings
        $summary.AppendLine("<h5>Key Findings</h5>") | Out-Null
        $summary.AppendLine("<ul>") | Out-Null
        $summary.AppendLine("<li>Monitored <strong>$($analytics.Metrics.UniqueProcesses)</strong> unique processes across the system</li>") | Out-Null
        $summary.AppendLine("<li>Recorded <strong>$($analytics.Metrics.UniqueOperations)</strong> distinct operation types</li>") | Out-Null
        $summary.AppendLine("<li>Identified <strong>$($analytics.Metrics.UniqueErrors)</strong> unique error conditions</li>") | Out-Null

        if ($analytics.Metrics.AccessDeniedCount -gt 100) {
            $summary.AppendLine("<li class='text-warning'><strong>$($analytics.Metrics.AccessDeniedCount)</strong> access denied events detected - potential security or permission issues</li>") | Out-Null
        }

        if ($analytics.Anomalies.Count -gt 0) {
            $summary.AppendLine("<li class='text-danger'><strong>$($analytics.Anomalies.Count)</strong> anomalous process behaviors identified</li>") | Out-Null
        }
        $summary.AppendLine("</ul>") | Out-Null

        $summary.AppendLine('</div></div>') | Out-Null

        return $summary.ToString()
    }

    # Generate Metrics Dashboard
    hidden [string] GenerateMetricsDashboard([hashtable]$analytics, [hashtable]$processedData) {
        $metrics = New-Object StringBuilder

        $metrics.AppendLine('<div class="container mt-4">') | Out-Null
        $metrics.AppendLine('<h2 class="section-title"><i class="fas fa-tachometer-alt me-2"></i>Key Performance Indicators</h2>') | Out-Null
        $metrics.AppendLine('<div class="row">') | Out-Null

        # Total Events
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-database fa-3x text-primary mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-primary">' + $analytics.Metrics.TotalEvents.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Total Events</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Error Rate
        $errorPct = [Math]::Round($analytics.Metrics.ErrorRate * 100, 2)
        $errorClass = if ($errorPct -gt 10) { "danger" } elseif ($errorPct -gt 5) { "warning" } else { "success" }
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine("<i class='fas fa-exclamation-triangle fa-3x text-$errorClass mb-3'></i>") | Out-Null
        $metrics.AppendLine("<div class='metric-value text-$errorClass'>$errorPct%</div>") | Out-Null
        $metrics.AppendLine('<div class="metric-label">Error Rate</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Unique Processes
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-cogs fa-3x text-info mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-info">' + $analytics.Metrics.UniqueProcesses.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Unique Processes</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        # Events Per Second
        $metrics.AppendLine('<div class="col-md-3 col-sm-6">') | Out-Null
        $metrics.AppendLine('<div class="metric-card card text-center p-4">') | Out-Null
        $metrics.AppendLine('<i class="fas fa-clock fa-3x text-warning mb-3"></i>') | Out-Null
        $metrics.AppendLine('<div class="metric-value text-warning">' + $analytics.Metrics.EventsPerSecond.ToString('N0') + '</div>') | Out-Null
        $metrics.AppendLine('<div class="metric-label">Events/Second</div>') | Out-Null
        $metrics.AppendLine('</div></div>') | Out-Null

        $metrics.AppendLine('</div></div>') | Out-Null

        return $metrics.ToString()
    }

    # Generate Health Score Section
    hidden [string] GenerateHealthScoreSection([hashtable]$analytics) {
        $section = New-Object StringBuilder

        $healthScore = [Math]::Round($analytics.HealthScore, 1)
        $scoreColor = if ($healthScore -ge 80) { "success" }
                     elseif ($healthScore -ge 60) { "info" }
                     elseif ($healthScore -ge 40) { "warning" }
                     else { "danger" }

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body text-center">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-heartbeat me-2"></i>System Health Score</h2>') | Out-Null
        $section.AppendLine('<div class="row align-items-center">') | Out-Null
        $section.AppendLine('<div class="col-md-6">') | Out-Null
        $section.AppendLine('<canvas id="healthScoreGauge" width="300" height="150"></canvas>') | Out-Null
        $section.AppendLine('</div>') | Out-Null
        $section.AppendLine('<div class="col-md-6 text-start">') | Out-Null
        $section.AppendLine("<h3 class='text-$scoreColor'>$healthScore / 100</h3>") | Out-Null
        $section.AppendLine('<p class="lead">Overall system health indicator based on error rates, anomalies, and risk factors.</p>') | Out-Null
        $section.AppendLine('<div class="progress" style="height: 30px;">') | Out-Null
        $section.AppendLine("<div class='progress-bar bg-$scoreColor' role='progressbar' style='width: $healthScore%' aria-valuenow='$healthScore' aria-valuemin='0' aria-valuemax='100'>$healthScore%</div>") | Out-Null
        $section.AppendLine('</div>') | Out-Null
        $section.AppendLine('</div></div></div></div></div>') | Out-Null

        return $section.ToString()
    }

    # Generate Risk Assessment Section
    hidden [string] GenerateRiskAssessmentSection([hashtable]$analytics) {
        $section = New-Object StringBuilder
        $risk = $analytics.RiskAssessment

        $section.AppendLine('<div class="container mt-4">') | Out-Null
        $section.AppendLine('<h2 class="section-title"><i class="fas fa-shield-alt me-2"></i>Risk Assessment</h2>') | Out-Null
        $section.AppendLine('<div class="card">') | Out-Null
        $section.AppendLine('<div class="card-body">') | Out-Null

        # Risk Score
        $section.AppendLine('<div class="row mb-4">') | Out-Null
        $section.AppendLine('<div class="col-md-12">') | Out-Null
        $section.AppendLine("<h4>Overall Risk Level: <span class='badge bg-$($risk.Color) fs-5'>$($risk.Level)</span></h4>") | Out-Null
        $section.AppendLine("<p>Risk Score: <strong>$($risk.Total)</strong> out of 100</p>") | Out-Null
        $section.AppendLine('</div></div>') | Out-Null

        # Risk Components
        $section.AppendLine('<div class="row">') | Out-Null

        $components = @(
            @{ Name = "Error Impact"; Score = $risk.ErrorScore; Weight = "40%" },
            @{ Name = "Frequency"; Score = $risk.FrequencyScore; Weight = "30%" },
            @{ Name = "System Impact"; Score = $risk.ImpactScore; Weight = "20%" },
            @{ Name = "Security"; Score = $risk.SecurityScore; Weight = "10
