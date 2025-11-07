#Requires -Version 5.1

<#
.SYNOPSIS
    Test script for CSV Post-Processing functionality

.DESCRIPTION
    Tests the enhanced StreamingCSVProcessor with post-processing capabilities
#>

param(
    [string]$TestFile = ""
)

$ErrorActionPreference = 'Stop'

Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       CSV Post-Processing Test Suite                               ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Load the streaming processor
$scriptPath = Join-Path $PSScriptRoot "StreamingCSVProcessor.ps1"
Write-Host "[1/5] Loading StreamingCSVProcessor..." -ForegroundColor Yellow

try {
    $content = Get-Content -Path $scriptPath -Raw
    Invoke-Expression $content
    Write-Host "  ✓ StreamingCSVProcessor loaded" -ForegroundColor Green
}
catch {
    Write-Error "Failed to load StreamingCSVProcessor: $($_.Exception.Message)"
    exit 1
}

# Test 1: Verify classes are loaded
Write-Host "`n[2/5] Verifying classes..." -ForegroundColor Yellow

try {
    $options = [CSVPostProcessingOptions]::new()
    Write-Host "  ✓ CSVPostProcessingOptions class available" -ForegroundColor Green

    $stats = [CSVPostProcessingStats]::new()
    Write-Host "  ✓ CSVPostProcessingStats class available" -ForegroundColor Green

    $processor = [StreamingCSVProcessor]::new(1000, $true)
    Write-Host "  ✓ StreamingCSVProcessor class available" -ForegroundColor Green
}
catch {
    Write-Error "Class verification failed: $($_.Exception.Message)"
    exit 1
}

# Test 2: Create sample CSV data
Write-Host "`n[3/5] Creating test data..." -ForegroundColor Yellow

$testDir = Join-Path $PSScriptRoot "Test-Data"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

$testCsvPath = Join-Path $testDir "test-sample.csv"

# Create sample CSV with various scenarios
$sampleData = @"
Time of Day,Process Name,PID,Operation,Path,Result,Detail
12:00:00.000,explorer.exe,1234,CreateFile,C:\Windows\test.txt,SUCCESS,Length: 100
12:00:01.000,chrome.exe,5678,RegOpenKey,HKLM\Software,NAME NOT FOUND,
12:00:02.000,explorer.exe,1234,CreateFile,C:\Windows\test.txt,SUCCESS,Length: 100
12:00:03.000,powershell.exe,9012,ReadFile,C:\Users\test.ps1,ACCESS DENIED,
12:00:04.000,notepad.exe,3456,WriteFile,C:\Temp\notes.txt,SUCCESS,Bytes: 500
12:00:05.000,chrome.exe,5678,RegQueryValue,HKLM\Software,BUFFER OVERFLOW,
12:00:06.000,explorer.exe,1234,DeleteFile,C:\Temp\old.dat,PATH NOT FOUND,
12:00:07.000,powershell.exe,9012,CreateFile,C:\Scripts\run.ps1,SHARING VIOLATION,
12:00:08.000,notepad.exe,3456,ReadFile,C:\Temp\notes.txt,SUCCESS,Length: 500
12:00:09.000,explorer.exe,1234,CreateFile,C:\Windows\test.txt,SUCCESS,Length: 100
"@

$sampleData | Out-File -FilePath $testCsvPath -Encoding UTF8 -Force
Write-Host "  ✓ Test CSV created: $testCsvPath" -ForegroundColor Green
Write-Host "    - 10 total records" -ForegroundColor Gray
Write-Host "    - 5 SUCCESS results (should be filtered)" -ForegroundColor Gray
Write-Host "    - 2 duplicate records (should be removed)" -ForegroundColor Gray
Write-Host "    - 5 error records (should be retained)" -ForegroundColor Gray

# Test 3: Process without post-processing
Write-Host "`n[4/5] Testing WITHOUT post-processing..." -ForegroundColor Yellow

$processor1 = [StreamingCSVProcessor]::new(1000, $true)
$result1 = $processor1.ProcessFile($testCsvPath)

Write-Host "  Records Processed: $($result1.RecordCount)" -ForegroundColor Cyan
Write-Host "  Errors: $($result1.ErrorCount)" -ForegroundColor Cyan

# Test 4: Process WITH post-processing
Write-Host "`n[5/5] Testing WITH post-processing..." -ForegroundColor Yellow

$processor2 = [StreamingCSVProcessor]::new(1000, $true)
$result2 = $processor2.ProcessFileWithPostProcessing($testCsvPath)

if ($result2.Success) {
    Write-Host "  ✓ Processing successful" -ForegroundColor Green

    if ($result2.PostProcessing) {
        $pp = $result2.PostProcessing

        Write-Host "`n  📊 Post-Processing Statistics:" -ForegroundColor Cyan
        Write-Host "    Total Processed: $($pp.Statistics.TotalProcessed)" -ForegroundColor White
        Write-Host "    Records Retained: $($pp.Statistics.Retained)" -ForegroundColor Green
        Write-Host "    Success Filtered: $($pp.Statistics.SuccessFiltered)" -ForegroundColor Yellow
        Write-Host "    Duplicates Removed: $($pp.Statistics.DuplicatesRemoved)" -ForegroundColor Yellow
        Write-Host "    Invalid Skipped: $($pp.Statistics.InvalidSkipped)" -ForegroundColor Red

        Write-Host "`n  📈 Data Quality Metrics:" -ForegroundColor Magenta
        Write-Host "    Retention Rate: $($pp.DataQuality.RetentionRate)%" -ForegroundColor White
        Write-Host "    Success Filter Rate: $($pp.DataQuality.SuccessFilterRate)%" -ForegroundColor White
        Write-Host "    Duplicate Rate: $($pp.DataQuality.DuplicateRate)%" -ForegroundColor White

        # Verify output files
        $cleanedFile = Join-Path $testDir "test-sample-cleaned.csv"
        $archiveDir = Join-Path $testDir "Archive"
        $successFile = Join-Path $archiveDir "test-sample-success.csv"

        Write-Host "`n  📁 Output Files:" -ForegroundColor Cyan
        if (Test-Path $cleanedFile) {
            $cleanedLines = (Get-Content $cleanedFile).Count
            Write-Host "    ✓ Cleaned file: $cleanedFile ($cleanedLines lines including header)" -ForegroundColor Green
        }
        if (Test-Path $successFile) {
            $successLines = (Get-Content $successFile).Count
            Write-Host "    ✓ Success archive: $successFile ($successLines lines including header)" -ForegroundColor Green
        }

        # Validation
        Write-Host "`n  ✅ Validation:" -ForegroundColor Green
        $expectedRetained = 3  # 5 errors - 2 duplicates = 3
        $expectedFiltered = 5   # 5 success results
        $expectedDuplicates = 2 # 2 duplicate success records

        $validationPassed = $true

        if ($pp.Statistics.Retained -eq $expectedRetained) {
            Write-Host "    ✓ Retained count correct: $($pp.Statistics.Retained)" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Retained count mismatch: Expected $expectedRetained, Got $($pp.Statistics.Retained)" -ForegroundColor Red
            $validationPassed = $false
        }

        if ($pp.Statistics.SuccessFiltered -eq $expectedFiltered) {
            Write-Host "    ✓ Success filtered correct: $($pp.Statistics.SuccessFiltered)" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Success filtered mismatch: Expected $expectedFiltered, Got $($pp.Statistics.SuccessFiltered)" -ForegroundColor Red
            $validationPassed = $false
        }

        if ($pp.Statistics.DuplicatesRemoved -eq $expectedDuplicates) {
            Write-Host "    ✓ Duplicates removed correct: $($pp.Statistics.DuplicatesRemoved)" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Duplicates mismatch: Expected $expectedDuplicates, Got $($pp.Statistics.DuplicatesRemoved)" -ForegroundColor Red
            $validationPassed = $false
        }

        Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        if ($validationPassed) {
            Write-Host "║               ✅ ALL TESTS PASSED SUCCESSFULLY                       ║" -ForegroundColor Green
        } else {
            Write-Host "║               ⚠️  SOME TESTS FAILED                                  ║" -ForegroundColor Yellow
        }
        Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

        if ($validationPassed) {
            exit 0
        } else {
            exit 1
        }
    }
    else {
        Write-Warning "Post-processing data not available in result"
        exit 1
    }
}
else {
    Write-Error "Processing failed: $($result2.Error)"
    exit 1
}
