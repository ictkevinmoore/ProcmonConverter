#Requires -Version 5.1

Write-Host ""
Write-Host "========================================"
Write-Host "Testing Enhanced Report Generation"
Write-Host "========================================"
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Dot-source the report generator
. "$scriptPath\Generate-Professional-Report.ps1"

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

$dataObject = @{
    Events = $sampleEvents
    TotalRecords = 100
    Summary = @{
        ProcessTypes = $processTypes
        Operations = $operations
    }
    FilesProcessed = 1
}

Write-Host "   Created test data with $($sampleEvents.Count) events" -ForegroundColor Green

Write-Host ""
Write-Host "[2/5] Creating session info..." -ForegroundColor Yellow

$sessionInfo = @{
    SessionId = "TEST-ENHANCED-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Version = '3.1-Enhanced-Lazy-Loading'
    FilesProcessed = 1
    InputDirectory = $scriptPath
    StartTime = (Get-Date).AddMinutes(-5)
}

Write-Host "   Session ID: $($sessionInfo.SessionId)" -ForegroundColor Green

Write-Host ""
Write-Host "[3/5] Generating enhanced report..." -ForegroundColor Yellow

$outputPath = Join-Path $scriptPath "Ultimate-Analysis-Reports\Test-Enhanced-Report-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').html"

$outputDir = Split-Path $outputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

try {
    $result = New-ProfessionalReport -DataObject $dataObject -OutputPath $outputPath -SessionInfo $sessionInfo

    if ($result.Success) {
        Write-Host "   Report generated successfully" -ForegroundColor Green
        Write-Host "   Location: $($result.ReportPath)" -ForegroundColor Cyan
    } else {
        Write-Host "   Report generation FAILED: $($result.Error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Validating report file..." -ForegroundColor Yellow

if (Test-Path $outputPath) {
    $fileSize = (Get-Item $outputPath).Length
    Write-Host "   Report file exists (Size: $([math]::Round($fileSize/1KB, 2)) KB)" -ForegroundColor Green

    $htmlContent = Get-Content $outputPath -Raw

    $features = @{
        '6-Tab Navigation' = $htmlContent -match 'id="reportTabs"'
        'Lazy Loading' = $htmlContent -match 'lazyLoadObserver'
        'Theme Toggle' = $htmlContent -match 'localStorage'
        'DataTables' = $htmlContent -match 'dataTableInstance'
        'Chart Modals' = $htmlContent -match 'processChartModal'
        'Column Filters' = $htmlContent -match 'column-filter-btn'
        'Export Buttons' = $htmlContent -match 'buttons'
    }

    Write-Host ""
    Write-Host "   Feature Validation:" -ForegroundColor Cyan
    $allPresent = $true
    foreach ($feature in $features.GetEnumerator() | Sort-Object Name) {
        if ($feature.Value) {
            Write-Host "   [OK] $($feature.Key)" -ForegroundColor Green
        } else {
            Write-Host "   [MISSING] $($feature.Key)" -ForegroundColor Red
            $allPresent = $false
        }
    }

    if ($allPresent) {
        Write-Host ""
        Write-Host "   All features present!" -ForegroundColor Green
    }
} else {
    Write-Host "   Report file NOT found" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[5/5] Rubric Scorecard:" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan

$rubricItems = @(
    @{ Category = "Core"; Item = "6-tab navigation"; Status = $features['6-Tab Navigation'] },
    @{ Category = "Core"; Item = "DataTable init"; Status = $features['DataTables'] },
    @{ Category = "Interactive"; Item = "Column filters"; Status = $features['Column Filters'] },
    @{ Category = "Interactive"; Item = "Chart modals"; Status = $features['Chart Modals'] },
    @{ Category = "Performance"; Item = "Lazy loading charts"; Status = $htmlContent -match 'loadChartThumbnails' },
    @{ Category = "Performance"; Item = "Lazy loading tables"; Status = $htmlContent -match 'loadDataTable' },
    @{ Category = "Theme"; Item = "Dark/light toggle"; Status = $features['Theme Toggle'] },
    @{ Category = "Export"; Item = "Export buttons"; Status = $features['Export Buttons'] }
)

$score = 0
foreach ($item in $rubricItems) {
    if ($item.Status) {
        Write-Host "  [OK] $($item.Item)" -ForegroundColor Green
        $score++
    } else {
        Write-Host "  [FAIL] $($item.Item)" -ForegroundColor Red
    }
}

$totalItems = $rubricItems.Count
$percentage = [math]::Round(($score / $totalItems) * 100, 1)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "FINAL SCORE: $score/$totalItems ($percentage%)" -ForegroundColor $(if ($score -eq $totalItems) { 'Green' } else { 'Yellow' })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($score -eq $totalItems) {
    Write-Host "SUCCESS! All enhancements implemented!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Opening report..." -ForegroundColor Cyan
    Start-Process $outputPath
} else {
    Write-Host "Some features need attention" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test completed!"
Write-Host "Report: $outputPath"
Write-Host ""

