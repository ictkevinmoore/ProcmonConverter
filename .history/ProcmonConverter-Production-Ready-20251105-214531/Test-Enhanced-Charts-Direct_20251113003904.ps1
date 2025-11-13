# Test script to directly generate an enhanced report with sample data

# Source the report generator
. ".\Generate-Professional-Report.ps1"

Write-Host "Creating sample data for report generation..." -ForegroundColor Cyan

# Create sample events data
$sampleEvents = @()
for ($i = 0; $i -lt 100; $i++) {
    $sampleEvents += @{
        TimeOfDay = (Get-Date).AddMinutes(-$i).ToString("HH:mm:ss.fff")
        ProcessName = @("chrome.exe", "explorer.exe", "svchost.exe", "System", "powershell.exe")[$i % 5]
        PID = 1000 + ($i % 5)
        Operation = @("RegOpenKey", "CreateFile", "ReadFile", "WriteFile", "CloseFile")[$i % 5]
        Path = "C:\Windows\System32\test$i.dll"
        Result = if ($i % 10 -eq 0) { "ACCESS DENIED" } elseif ($i % 15 -eq 0) { "NAME NOT FOUND" } else { "SUCCESS" }
        Detail = "Length: $($i * 100)"
    }
}

# Create data object with proper structure
$dataObject = @{
    Events = $sampleEvents
    TotalRecords = $sampleEvents.Count
    FilesProcessed = 1
    Summary = @{
        ProcessTypes = @{
            'chrome.exe' = 20
            'explorer.exe' = 20
            'svchost.exe' = 20
            'System' = 20
            'powershell.exe' = 20
        }
        Operations = @{
            'RegOpenKey' = 20
            'CreateFile' = 20
            'ReadFile' = 20
            'WriteFile' = 20
            'CloseFile' = 20
        }
    }
}

# Create session info
$sessionInfo = @{
    SessionId = "TEST-ENHANCED-CHARTS-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Version = "1.0-Enhanced"
    FilesProcessed = 1
    InputDirectory = "Test Data"
    StartTime = Get-Date
}

Write-Host "Generating enhanced report..." -ForegroundColor Yellow

# Generate the report
$outputPath = ".\Test-Enhanced-Charts-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
$result = New-ProfessionalReport -DataObject $dataObject -OutputPath $outputPath -SessionInfo $sessionInfo

if ($result.Success) {
    Write-Host "`nReport generated successfully!" -ForegroundColor Green
    Write-Host "Location: $outputPath" -ForegroundColor Cyan
    Write-Host "`nOpening report in browser..." -ForegroundColor Yellow

    # Open in default browser
    Start-Process $outputPath

    Write-Host "`nPlease verify the following enhancements:" -ForegroundColor Cyan
    Write-Host "  1. Charts tab has 7 chart type buttons (Bar, Line, Area, Doughnut, Pie, Radar, PolarArea)" -ForegroundColor White
    Write-Host "  2. Chart buttons have Font Awesome icons" -ForegroundColor White
    Write-Host "  3. Charts switch between all 7 types when buttons are clicked" -ForegroundColor White
    Write-Host "  4. Area charts show gradient backgrounds" -ForegroundColor White
    Write-Host "  5. Tooltips show percentages in addition to values" -ForegroundColor White
    Write-Host "  6. Charts have smooth animations" -ForegroundColor White
    Write-Host "  7. Download buttons work for PNG/SVG" -ForegroundColor White
    Write-Host "  8. All CSV data displays in Events tab" -ForegroundColor White
    Write-Host "  9. Column filters work on all columns" -ForegroundColor White
    Write-Host " 10. Row selection and export features work" -ForegroundColor White
} else {
    Write-Host "`nReport generation failed!" -ForegroundColor Red
    Write-Host "Error: $($result.Error)" -ForegroundColor Red
}

