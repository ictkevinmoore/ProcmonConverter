<#
.SYNOPSIS
    Test script for the new Modular HTML Generation System

.DESCRIPTION
    Demonstrates how to use the new modular HTML generator to create professional reports.
    Includes sample data and configuration examples.

.NOTES
    Author: AI Assistant
    Version: 1.0.0
#>

# Import the main HTML generator module
Import-Module ".\HTMLGenerator\HTMLGenerator.psm1" -Force

function New-SampleData {
    <#
    .SYNOPSIS
        Creates sample Procmon data for testing
    #>
    param(
        [Parameter(Mandatory = $false)]
        [int]$EventCount = 1000
    )

    # Generate sample events
    $events = @()
    $processes = @('chrome.exe', 'explorer.exe', 'svchost.exe', 'lsass.exe', 'winlogon.exe', 'csrss.exe')
    $operations = @('RegOpenKey', 'CreateFile', 'ReadFile', 'WriteFile', 'QueryValue', 'SetValue')

    for ($i = 0; $i -lt $EventCount; $i++) {
        $process = $processes | Get-Random
        $operation = $operations | Get-Random

        $events += @{
            TimeOfDay = "{0:HH:mm:ss.fff}" -f (Get-Date).AddSeconds($i * 0.1)
            ProcessName = $process
            Operation = $operation
            Path = "C:\Windows\System32\$process"
            Result = "SUCCESS"
        }
    }

    # Calculate summaries
    $processSummary = @{}
    $operationSummary = @{}

    foreach ($event in $events) {
        $processSummary[$event.ProcessName] = ($processSummary[$event.ProcessName] ?? 0) + 1
        $operationSummary[$event.Operation] = ($operationSummary[$event.Operation] ?? 0) + 1
    }

    return @{
        Events = $events
        TotalRecords = $events.Count
        Summary = @{
            ProcessTypes = $processSummary
            Operations = $operationSummary
            FilesProcessed = 1
        }
    }
}

function Test-ModularHTMLGenerator {
    <#
    .SYNOPSIS
        Tests the modular HTML generator with sample data
    #>

    Write-Host "Testing Modular HTML Generation System" -ForegroundColor Cyan
    Write-Host "=" * 50

    try {
        # Create sample data
        Write-Host "Generating sample data..." -NoNewline
        $sampleData = New-SampleData -EventCount 500
        Write-Host " Done" -ForegroundColor Green

        # Create session info
        $sessionInfo = @{
            SessionId = "TEST-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Version = '1.0.0'
            FilesProcessed = 1
            InputDirectory = 'C:\TestData'
            StartTime = Get-Date
        }

        # Test basic report generation
        Write-Host "Testing basic report generation..." -NoNewline
        $outputPath = ".\Test-Report-Basic-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

        $result = New-HTMLReport -DataObject $sampleData -SessionInfo $sessionInfo -OutputPath $outputPath -TemplatePath ".\Templates"

        if ($result.Success) {
            Write-Host " Success" -ForegroundColor Green
            Write-Host "  Report saved to: $outputPath" -ForegroundColor Yellow
        }
        else {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
            return
        }

        # Test with custom configuration
        Write-Host "Testing with custom configuration..." -NoNewline
        $customConfig = @{
            MaxSampleSize = 100
            TopItemsCount = 5
            Theme = 'dark'
            SummaryConfig = @{
                EnableHealthScore = $true
                MaxInsights = 5
            }
        }

        $outputPath2 = ".\Test-Report-Custom-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
        $result2 = New-HTMLReport -DataObject $sampleData -SessionInfo $sessionInfo -OutputPath $outputPath2 -TemplatePath ".\Templates" -Config $customConfig

        if ($result2.Success) {
            Write-Host " Success" -ForegroundColor Green
            Write-Host "  Custom report saved to: $outputPath2" -ForegroundColor Yellow
        }
        else {
            Write-Host " Failed" -ForegroundColor Red
            Write-Host "  Error: $($result2.Error)" -ForegroundColor Red
        }

        # Test error handling
        Write-Host "Testing error handling..." -NoNewline
        $invalidData = @{
            Events = $null  # Invalid: missing events
            TotalRecords = -1  # Invalid: negative count
            Summary = @{}
        }

        $outputPath3 = ".\Test-Report-Error-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
        $result3 = New-HTMLReport -DataObject $invalidData -SessionInfo $sessionInfo -OutputPath $outputPath3 -TemplatePath ".\Templates"

        if (-not $result3.Success) {
            Write-Host " Success (Expected error caught)" -ForegroundColor Green
        }
        else {
            Write-Host " Unexpected success" -ForegroundColor Yellow
        }

        Write-Host "`nAll tests completed!" -ForegroundColor Green
        Write-Host "Generated reports:" -ForegroundColor Cyan
        Get-ChildItem ".\Test-Report-*.html" | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor Yellow
        }

    }
    catch {
        Write-Host "Test failed with exception: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
}

function Show-UsageExamples {
    <#
    .SYNOPSIS
        Shows usage examples for the modular HTML generator
    #>

    Write-Host "`nUsage Examples for Modular HTML Generator" -ForegroundColor Cyan
    Write-Host "=" * 50

    $examples = @"

# Example 1: Basic Usage
`$data = @{
    Events = `$processedEvents
    TotalRecords = 15000
    Summary = @{
        ProcessTypes = @{ 'chrome.exe' = 5000; 'explorer.exe' = 3000 }
        Operations = @{ 'RegOpenKey' = 8000; 'CreateFile' = 7000 }
    }
}
`$session = @{
    SessionId = 'PROC-2025-001'
    Version = '1.0'
    FilesProcessed = 1
}
New-HTMLReport -DataObject `$data -SessionInfo `$session -OutputPath "report.html"

# Example 2: Custom Configuration
`$config = @{
    MaxSampleSize = 1000
    TopItemsCount = 10
    Theme = 'dark'
    SummaryConfig = @{
        EnableHealthScore = `$true
        MaxInsights = 8
    }
}
New-HTMLReport -DataObject `$data -SessionInfo `$session -OutputPath "custom-report.html" -Config `$config

# Example 3: Batch Processing
Get-ChildItem "C:\ProcmonData\*.csv" | ForEach-Object {
    `$csvData = Import-Csv `$_.FullName
    `$data = ConvertTo-DataBindingFormat -DataObject `$csvData -SessionInfo `$session
    `$outputPath = "Reports\$($_.BaseName)-report.html"
    New-HTMLReport -DataObject `$data -SessionInfo `$session -OutputPath `$outputPath
}

# Example 4: Advanced Component Usage
`$generator = [HTMLGenerator]::new(".\Templates", `$config)
`$result = `$generator.GenerateReport(`$data)
if (`$result.Success) {
    `$generator.SaveReport(`$result.HTML, "advanced-report.html")
    Write-Host "Advanced report generated with $($result.Metadata.ComponentCount) components"
}
"@

    Write-Host $examples -ForegroundColor Gray
}

# Run tests if script is executed directly
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Test-ModularHTMLGenerator
    Show-UsageExamples
}

Export-ModuleMember -Function Test-ModularHTMLGenerator, New-SampleData, Show-UsageExamples

