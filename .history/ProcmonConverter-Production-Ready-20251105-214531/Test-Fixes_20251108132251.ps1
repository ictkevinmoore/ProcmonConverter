# Test the fixes for HTML report issues

Write-Host "Testing HTML Report Fixes..." -ForegroundColor Cyan

# Import the report generation function
. ".\Generate-Professional-Report.ps1"

# Create test data
$testData = @{
    Events = @(
        @{ TimeOfDay = "10:30:15"; ProcessName = "chrome.exe"; PID = "1234"; Operation = "CreateFile"; Path = "C:\Users\test\Downloads\file.txt"; Result = "SUCCESS" },
        @{ TimeOfDay = "10:30:16"; ProcessName = "explorer.exe"; PID = "5678"; Operation = "RegOpenKey"; Path = "HKCU\Software\Microsoft\Windows"; Result = "SUCCESS" },
        @{ TimeOfDay = "10:30:17"; ProcessName = "chrome.exe"; PID = "1234"; Operation = "ReadFile"; Path = "C:\Users\test\Downloads\file.txt"; Result = "SUCCESS" }
    )
    TotalRecords = 1000
    FilesProcessed = 1
    Summary = @{
        ProcessTypes = @{
            "chrome.exe" = 500
            "explorer.exe" = 300
            "notepad.exe" = 200
        }
        Operations = @{
            "CreateFile" = 400
            "RegOpenKey" = 300
            "ReadFile" = 300
        }
    }
}

$sessionInfo = @{
    SessionId = "TEST-FIXES-2025"
    Version = "2.0"
    FilesProcessed = 1
    InputDirectory = "C:\Test"
    StartTime = Get-Date
}

# Generate report
$result = New-ProfessionalReport -DataObject $testData -OutputPath "Test-Fixes-Report.html" -SessionInfo $sessionInfo

if ($result.Success) {
    Write-Host "✅ Report generated successfully!" -ForegroundColor Green
    Write-Host "📁 Output: Test-Fixes-Report.html" -ForegroundColor Green

    # Check file size
    $fileSize = (Get-Item "Test-Fixes-Report.html").Length
    Write-Host "📏 File size: $([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Green

    # Basic validation
    $content = Get-Content "Test-Fixes-Report.html" -Raw
    $validations = @(
        @{ Name = "CSV Export Fix"; Pattern = "csvHtml5" },
        @{ Name = "DataTables Fix"; Pattern = "Cannot reinitialise DataTable" },
        @{ Name = "All Events Tab"; Pattern = "Complete Event Details" },
        @{ Name = "Chart Types"; Pattern = "chart-type-btn" }
    )

    Write-Host "`n🔍 Validation Results:" -ForegroundColor Yellow
    foreach ($validation in $validations) {
        if ($content -match $validation.Pattern) {
            Write-Host "  ✅ $($validation.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $($validation.Name)" -ForegroundColor Red
        }
    }

} else {
    Write-Host "❌ Report generation failed!" -ForegroundColor Red
    Write-Host "Error: $($result.Error)" -ForegroundColor Red
}

Write-Host "`n🏁 Test completed!" -ForegroundColor Cyan

