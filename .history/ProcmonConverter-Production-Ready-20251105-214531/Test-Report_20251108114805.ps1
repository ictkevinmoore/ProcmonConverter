# Test script for Generate-Professional-Report.ps1

# Create sample data
$sampleData = @{
    Events = @(
        @{
            TimeOfDay = "10:30:15.123"
            ProcessName = "chrome.exe"
            PID = "1234"
            Operation = "CreateFile"
            Path = "C:\Users\test\file.txt"
            Result = "SUCCESS"
        },
        @{
            TimeOfDay = "10:30:16.456"
            ProcessName = "explorer.exe"
            PID = "5678"
            Operation = "RegOpenKey"
            Path = "HKCU\Software\Microsoft"
            Result = "SUCCESS"
        }
    )
    TotalRecords = 2
    Summary = @{
        ProcessTypes = @{
            'chrome.exe' = 1
            'explorer.exe' = 1
        }
        Operations = @{
            'CreateFile' = 1
            'RegOpenKey' = 1
        }
    }
}

# Create session info
$sessionInfo = @{
    SessionId = "TEST-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Version = '1.0.0'
    FilesProcessed = 1
    InputDirectory = 'C:\TestData'
    StartTime = Get-Date
}

# Test the function
try {
    Write-Host "Testing Generate-Professional-Report.ps1..." -ForegroundColor Cyan

    # Dot source the script to load functions
    . ".\Generate-Professional-Report.ps1"

    # Generate report
    $result = New-ProfessionalReport -DataObject $sampleData -SessionInfo $sessionInfo -OutputPath "Test-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"

    if ($result.Success) {
        Write-Host "SUCCESS: Report generated successfully!" -ForegroundColor Green
        Write-Host "Report path: $($result.ReportPath)" -ForegroundColor Yellow
        Write-Host "Data summary: $($result.DataSummary | ConvertTo-Json)" -ForegroundColor Gray
    } else {
        Write-Host "FAILED: $($result.Error)" -ForegroundColor Red
    }
} catch {
    Write-Host "EXCEPTION: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

