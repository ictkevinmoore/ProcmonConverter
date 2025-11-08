<#
.SYNOPSIS
    Summary Component for HTML Report Generation

.DESCRIPTION
    Generates the executive summary section of professional HTML reports.
    Includes key metrics, insights, and recommendations.

.NOTES
    Author: AI Assistant
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

class SummaryComponent {
    [hashtable]$Config
    [TemplateEngine]$TemplateEngine

    SummaryComponent([TemplateEngine]$templateEngine, [hashtable]$config = @{}) {
        $this.TemplateEngine = $templateEngine
        $this.Config = $config
    }

    [string] Render([hashtable]$data) {
        try {
            # Generate insights
            $insights = $this.GenerateInsights($data)

            # Generate recommendations
            $recommendations = $this.GenerateRecommendations($data)

            # Prepare template data
            $templateData = @{
                HealthScore = $this.CalculateHealthScore($data)
                Insights = $this.FormatListItems($insights)
                Recommendations = $this.FormatListItems($recommendations)
            }

            # Render the summary section
            return $this.TemplateEngine.Render('SummaryTemplate', $templateData)
        }
        catch {
            Write-Warning "Failed to render summary component: $($_.Exception.Message)"
            return "<div class='alert alert-warning'>Unable to generate summary section</div>"
        }
    }

    [int] CalculateHealthScore([hashtable]$data) {
        $score = 100

        # Deduct points based on various factors
        if ($data.Insights.TopProcess) {
            $percentage = $data.Insights.ProcessPercentage
            if ($percentage -gt 50) {
                $score -= 20  # High concentration on single process
            }
            elseif ($percentage -gt 30) {
                $score -= 10
            }
        }

        # Check for error rates (if available)
        if ($data.Summary.ContainsKey('ErrorRate')) {
            $errorRate = $data.Summary.ErrorRate
            if ($errorRate -gt 10) {
                $score -= 30
            }
            elseif ($errorRate -gt 5) {
                $score -= 15
            }
            elseif ($errorRate -gt 1) {
                $score -= 5
            }
        }

        # Check operation diversity
        if ($data.Summary.OperationTypes -lt 5) {
            $score -= 10  # Limited operation types
        }

        return [Math]::Max(0, [Math]::Min(100, $score))
    }

    [array] GenerateInsights([hashtable]$data) {
        $insights = @()

        # Process insights
        if ($data.Insights.TopProcess) {
            $insights += @{
                Type = "info"
                Text = "Top process '$($data.Insights.TopProcess.Name)' accounts for $($data.Insights.ProcessPercentage)% of all events"
                Icon = "fas fa-exclamation-triangle"
            }
        }

        # Operation insights
        if ($data.Insights.TopOperation) {
            $insights += @{
                Type = "info"
                Text = "Most common operation is '$($data.Insights.TopOperation.Name)' with $($data.Insights.TopOperation.Count) occurrences"
                Icon = "fas fa-cogs"
            }
        }

        # Volume insights
        if ($data.Summary.TotalRecords -gt 100000) {
            $insights += @{
                Type = "warning"
                Text = "High volume: $($data.Summary.TotalRecords.ToString('N0')) total events recorded"
                Icon = "fas fa-chart-line"
            }
        }

        # Process diversity
        $avgEvents = $data.Insights.AverageEventsPerProcess
        if ($avgEvents -gt 1000) {
            $insights += @{
                Type = "info"
                Text = "Average of $avgEvents events per unique process"
                Icon = "fas fa-users"
            }
        }

        return $insights
    }

    [array] GenerateRecommendations([hashtable]$data) {
        $recommendations = @()

        # Process concentration recommendations
        if ($data.Insights.ProcessPercentage -gt 40) {
            $recommendations += @{
                Type = "warning"
                Text = "Consider investigating high activity from '$($data.Insights.TopProcess.Name)' process"
                Icon = "fas fa-search"
            }
        }

        # Volume-based recommendations
        if ($data.Summary.TotalRecords -gt 50000) {
            $recommendations += @{
                Type = "info"
                Text = "Consider implementing sampling for large datasets to improve performance"
                Icon = "fas fa-filter"
            }
        }

        # Operation diversity recommendations
        if ($data.Summary.OperationTypes -lt 3) {
            $recommendations += @{
                Type = "info"
                Text = "Limited operation types detected - consider expanding monitoring scope"
                Icon = "fas fa-expand"
            }
        }

        # File processing recommendations
        if ($data.Summary.FilesProcessed -gt 10) {
            $recommendations += @{
                Type = "success"
                Text = "Successfully processed $($data.Summary.FilesProcessed) files"
                Icon = "fas fa-check-circle"
            }
        }

        return $recommendations
    }

    [string] FormatListItems([array]$items) {
        if (-not $items -or $items.Count -eq 0) {
            return "<li class='list-group-item'>No items to display</li>"
        }

        $result = ""
        foreach ($item in $items) {
            $cssClass = switch ($item.Type) {
                "warning" { "list-group-item-warning" }
                "success" { "list-group-item-success" }
                "info" { "list-group-item-info" }
                default { "" }
            }

            $iconHtml = if ($item.Icon) { "<i class='$($item.Icon) me-2'></i>" } else { "" }

            $result += "<li class='list-group-item $cssClass insight-clickable' data-type='$($item.Type)'>$iconHtml$($item.Text)</li>"
        }

        return $result
    }
}

# Helper function to create summary component
function New-SummaryComponent {
    <#
    .SYNOPSIS
        Creates a new SummaryComponent instance
    #>
    param(
        [Parameter(Mandatory = $true)]
        [TemplateEngine]$TemplateEngine,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    return [SummaryComponent]::new($TemplateEngine, $Config)
}

# Export functions
Export-ModuleMember -Function New-SummaryComponent

