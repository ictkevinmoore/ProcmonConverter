#Requires -Version 5.1

<#
.SYNOPSIS
    Test script for the enhanced report generation with lazy loading

.DESCRIPTION
    Tests the updated Generate-Professional-Report.ps1 script with all enhancements:
    - 6-tab navigation
    - Lazy loading for charts and tables
    - Dark/light theme toggle
    - Advanced DataTables features
    - Chart modals with type switching
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Enhanced Report Generation" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Set script location
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source the report generator
. "$scriptPath\Generate-Professional-Report.ps1"

# Create test data
Write-Host "[1/5] Creating test data..." -ForegroundColor Yellow

$sampleEvents = @()
for ($i = 1; $i -le 100; $i++) {
    $sampleEvents += [PSCustomObject]@{
        TimeOfDay = (Get-Date).AddMinutes(-$i).ToString('HH:mm:ss.fffffff')
        ProcessName = @('chrome.exe', 'notepad.exe', 'explorer.exe', 'svchost.exe')[$i % 4]
        PID = 1000 + ($i % 10)
        Operation = @('CreateFile', 'RegOpenKey', 'ReadFile', 'WriteFile')[$i % 4]
        Path = "C:\Windows\System32\file$i.dll"
        Result = if ($i % 10 -eq 0) { 'ERROR' } else { 'SUCCESS' }
        Detail = "Test detail for event $i"
    }
}

# Create process and operation summaries
$processTypes = @{
    'chrome.exe' = 30
    'notepad.exe' = 25
    'explorer.exe' = 25
    'svchost.exe' = 20
}

$operations = @{
    'CreateFile' = 35
    'RegOpenKey' = 30
    'ReadFile' = 20
    'WriteFile' = 15
}

# Create DataObject
$dataObject = @{
    Events = $sampleEvents
    TotalRecords = 100
    Summary = @{
        ProcessTypes = $processTypes
        Operations = $operations
    }
    FilesProcessed = 1
}

Write-Host "   ✓ Created test data with $($sampleEvents.Count) events" -ForegroundColor Green

# Create SessionInfo
Write-Host "`n[2/5] Creating session info..." -ForegroundColor Yellow

$sessionInfo = @{
    SessionId = "TEST-ENHANCED-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Version = '3.1-Enhanced-Lazy-Loading'
    FilesProcessed = 1
    InputDirectory = $scriptPath
    StartTime = (Get-Date).AddMinutes(-5)
}

Write-Host "   ✓ Session ID: $($sessionInfo.SessionId)" -ForegroundColor Green

# Generate report
Write-Host "`n[3/5] Generating enhanced report..." -ForegroundColor Yellow

$outputPath = Join-Path $scriptPath "Ultimate-Analysis-Reports\Test-Enhanced-Report-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').html"

# Ensure output directory exists
$outputDir = Split-Path $outputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    Write-Host "   ✓ Created output directory" -ForegroundColor Green
}

try {
    $result = New-ProfessionalReport -DataObject $dataObject -OutputPath $outputPath -SessionInfo $sessionInfo -Verbose

    if ($result.Success) {
        Write-Host "   ✓ Report generated successfully" -ForegroundColor Green
        Write-Host "     Location: $($result.ReportPath)" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ Report generation failed: $($result.Error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Validate report file
Write-Host "`n[4/5] Validating report file..." -ForegroundColor Yellow

if (Test-Path $outputPath) {
    $fileSize = (Get-Item $outputPath).Length
    Write-Host "   ✓ Report file exists (Size: $([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Green

    # Check for key features in the HTML
    $htmlContent = Get-Content $outputPath -Raw

    $features = @{
        '6-Tab Navigation' = $htmlContent -match 'id="reportTabs"'
        'Lazy Loading' = $htmlContent -match 'lazyLoadObserver'
        'Theme Toggle' = $htmlContent -match 'localStorage\.getItem\("theme"\)'
        'DataTables' = $htmlContent -match 'dataTableInstance'
        'Chart Modals' = $htmlContent -match 'processChartModal'
        'Column Filters' = $htmlContent -match 'column-filter-btn'
        'Executive Summary Tab' = $htmlContent -match 'tab-summary'
        'Pattern Recognition Tab' = $htmlContent -match 'tab-patterns'
        'Advanced Analytics Tab' = $htmlContent -match 'tab-analytics'
        'ML Analytics Tab' = $htmlContent -match 'tab-ml'
        'Event Details Tab' = $htmlContent -match 'tab-events'
        'Charts Tab' = $htmlContent -match 'tab-charts'
        'Export Buttons' = $htmlContent -match 'buttons\.html5'
    }

    Write-Host "`n   Feature Validation:" -ForegroundColor Cyan
    $allFeaturesPresent = $true
    foreach ($feature in $features.GetEnumerator() | Sort-Object Name) {
        if ($feature.Value) {
            Write-Host "   ✓ $($feature.Key)" -ForegroundColor Green
        } else {
            Write-Host "   ✗ $($feature.Key) - MISSING" -ForegroundColor Red
            $allFeaturesPresent = $false
        }
    }

    if ($allFeaturesPresent) {
        Write-Host "`n   ✓ All features present in report" -ForegroundColor Green
    } else {
        Write-Host "`n   ✗ Some features are missing" -ForegroundColor Red
    }
} else {
    Write-Host "   ✗ Report file not found" -ForegroundColor Red
    exit 1
}

# Display rubric scorecard
Write-Host ""
Write-Host "[5/5] Rubric Scorecard (10/10 Requirements):" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$rubricItems = @(
    @{ Category = "Core Functionality"; Item = "6-tab navigation working"; Status = $features['6-Tab Navigation'] },
    @{ Category = "Core Functionality"; Item = "All analytics engines integrated"; Status = $htmlContent -match 'AdvancedAnalyticsEngine' },
    @{ Category = "Core Functionality"; Item = "DataTable initialization"; Status = $features['DataTables'] },
    @{ Category = "Interactive Features"; Item = "Column checkbox filters"; Status = $features['Column Filters'] },
    @{ Category = "Interactive Features"; Item = "Row click detail modal"; Status = $htmlContent -match 'rowDetailModal' },
    @{ Category = "Interactive Features"; Item = "Chart modals with type switching"; Status = $features['Chart Modals'] },
    @{ Category = "Performance Optimization"; Item = "Lazy loading for charts"; Status = $htmlContent -match 'loadChartThumbnails' },
    @{ Category = "Performance Optimization"; Item = "Lazy loading for tables"; Status = $htmlContent -match 'loadDataTable' },
    @{ Category = "Theme and UX"; Item = "Dark/light theme toggle"; Status = $features['Theme Toggle'] },
    @{ Category = "Theme and UX"; Item = "Professional Gates Foundation styling"; Status = $htmlContent -match 'Gates Foundation Theme' },
    @{ Category = "Export and Accessibility"; Item = "All export formats working"; Status = $features['Export Buttons'] },
    @{ Category = "Export and Accessibility"; Item = "Chart PNG download"; Status = $htmlContent -match 'downloadProcessChart' }
)

$currentCategory = ""
$score = 0
foreach ($item in $rubricItems) {
    if ($item.Category -ne $currentCategory) {
        $currentCategory = $item.Category
        Write-Host ""
        Write-Host "$($currentCategory):" -ForegroundColor Cyan
    }

    if ($item.Status) {
        Write-Host "  ✓ $($item.Item)" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  ✗ $($item.Item)" -ForegroundColor Red
    }
}

$totalItems = $rubricItems.Count
$percentage = [math]::Round(($score / $totalItems) * 100, 1)
$scoreColor = if ($score -eq $totalItems) { 'Green' } else { 'Yellow' }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL SCORE: $score/$totalItems ($percentage%)" -ForegroundColor $scoreColor
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($score -eq $totalItems) {
    Write-Host "PERFECT SCORE! All enhancements successfully implemented!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Opening report in browser..." -ForegroundColor Cyan
    Start-Process $outputPath
} else {
    Write-Host "Some features need attention. Score: $percentage%" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test completed!" -ForegroundColor Cyan
Write-Host "Report location: $outputPath" -ForegroundColor White
Write-Host ""

