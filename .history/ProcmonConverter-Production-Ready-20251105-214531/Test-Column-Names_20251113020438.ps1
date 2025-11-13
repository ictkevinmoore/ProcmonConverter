#Requires -Version 5.1

<#
.SYNOPSIS
    Test script to verify column naming standardization

.DESCRIPTION
    Validates that all column headers match Procmon standard format:
    - Process Name (not "Process")
    - PID
    - Operation
    - Result
#>

Write-Host "`n=== Column Name Standardization Test ===" -ForegroundColor Cyan
Write-Host "Testing: Generate-Professional-Report.ps1" -ForegroundColor Yellow

# Load the script
$scriptPath = Join-Path $PSScriptRoot "Generate-Professional-Report.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "`nLoading script..." -ForegroundColor Yellow
. $scriptPath

# Create test data
$testData = @{
    Events = @(
        [PSCustomObject]@{
            TimeOfDay = "10:30:15.123"
            ProcessName = "chrome.exe"
            PID = "1234"
            Operation = "RegOpenKey"
            Path = "HKLM\Software\Test"
            Result = "SUCCESS"
        },
        [PSCustomObject]@{
            TimeOfDay = "10:30:16.456"
            ProcessName = "explorer.exe"
            PID = "5678"
            Operation = "CreateFile"
            Path = "C:\Windows\Test.txt"
            Result = "ACCESS DENIED"
        }
    )
    TotalRecords = 2
    Summary = @{
        ProcessTypes = @{
            'chrome.exe' = 1
            'explorer.exe' = 1
        }
        Operations = @{
            'RegOpenKey' = 1
            'CreateFile' = 1
        }
    }
}

$sessionInfo = @{
    SessionId = 'TEST-COLUMN-NAMES'
    Version = '1.0-TEST'
    FilesProcessed = 1
    InputDirectory = $PSScriptRoot
    StartTime = Get-Date
}

# Generate test report
$outputPath = Join-Path $PSScriptRoot "Test-Column-Names-Report.html"
Write-Host "`nGenerating test report..." -ForegroundColor Yellow

try {
    $result = New-ProfessionalReport -DataObject $testData -OutputPath $outputPath -SessionInfo $sessionInfo -Verbose

    if ($result.Success) {
        Write-Host "`n✓ Report generated successfully!" -ForegroundColor Green
        Write-Host "  Path: $outputPath" -ForegroundColor Gray

        # Verify column names in the HTML
        Write-Host "`nVerifying column headers..." -ForegroundColor Yellow
        $htmlContent = Get-Content $outputPath -Raw

        $checks = @{
            "Analysis Table - 'Process Name'" = ($htmlContent -match '<th>Process Name</th>' -and $htmlContent -match 'Process Name.*Event Count.*Error Count')
            "Events Table - 'Process Name'" = ($htmlContent -match '<th>Process Name</th>.*<th>PID</th>.*<th>Operation</th>')
            "No 'Process' (without Name)" = ($htmlContent -notmatch '<th>Process</th>')
            "PID column present" = ($htmlContent -match '<th>PID</th>')
            "Operation column present" = ($htmlContent -match '<th>Operation</th>')
            "Result column present" = ($htmlContent -match '<th>Result</th>')
        }

        $allPassed = $true
        foreach ($check in $checks.GetEnumerator()) {
            if ($check.Value) {
                Write-Host "  ✓ $($check.Key)" -ForegroundColor Green
            } else {
                Write-Host "  ✗ $($check.Key)" -ForegroundColor Red
                $allPassed = $false
            }
        }

        if ($allPassed) {
            Write-Host "`n=== ALL TESTS PASSED - 10/10 SCORE ===" -ForegroundColor Green
            Write-Host "`nColumn Naming Summary:" -ForegroundColor Cyan
            Write-Host "  ✓ Analysis Table: 'Process Name' header correct" -ForegroundColor Green
            Write-Host "  ✓ Events Table: 'Process Name' header correct" -ForegroundColor Green
            Write-Host "  ✓ All required columns present: Process Name, PID, Operation, Result" -ForegroundColor Green
            Write-Host "  ✓ Matches Procmon standard format" -ForegroundColor Green
            Write-Host "`nYou can view the test report at:" -ForegroundColor Yellow
            Write-Host "  $outputPath" -ForegroundColor Gray
        } else {
            Write-Host "`n=== SOME TESTS FAILED ===" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "`n✗ Report generation failed!" -ForegroundColor Red
        Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "`n✗ Test failed with exception!" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Stack: $($_.ScriptStackTrace)" -ForegroundColor Gray
    exit 1
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan

