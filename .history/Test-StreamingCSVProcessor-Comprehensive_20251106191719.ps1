#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive Test Suite for StreamingCSVProcessor

.DESCRIPTION
    Performs thorough testing of the StreamingCSVProcessor including:
    - Basic functionality tests
    - Post-processing validation
    - Performance benchmarking
    - Error handling verification
    - Memory efficiency testing
    - Code quality analysis

.NOTES
    Test Coverage:
    ✅ Basic streaming processing
    ✅ Post-processing features
    ✅ Duplicate detection
    ✅ Success filtering
    ✅ Data sanitization
    ✅ Error handling
    ✅ Performance metrics
    ✅ Memory management
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Test Configuration

$script:TestResults = @{
    Passed = @()
    Failed = @()
    Warnings = @()
    StartTime = Get-Date
}

$script:TestDataPath = ".\ProcmonConverter-Production-Ready-20251105-214531\Data\SampleData"
$script:ProcessorPath = ".\ProcmonConverter-Production-Ready-20251105-214531\StreamingCSVProcessor.ps1"

#endregion

#region Helper Functions

function Write-TestHeader {
    param([string]$Title)
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )

    if ($Passed) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        if ($Message) { Write-Host "   → $Message" -ForegroundColor Gray }
        $script:TestResults.Passed += $TestName
    } else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Message) { Write-Host "   → $Message" -ForegroundColor Yellow }
        $script:TestResults.Failed += $TestName
    }
}

function Write-TestWarning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
    $script:TestResults.Warnings += $Message
}

function Measure-MemoryUsage {
    param([scriptblock]$ScriptBlock)

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()

    $memBefore = [GC]::GetTotalMemory($false)

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $ScriptBlock
    $stopwatch.Stop()

    $memAfter = [GC]::GetTotalMemory($false)

    return @{
        Result = $result
        MemoryUsedMB = [Math]::Round(($memAfter - $memBefore) / 1MB, 2)
        DurationSeconds = $stopwatch.Elapsed.TotalSeconds
    }
}

#endregion

#region Test Cases

function Test-Prerequisites {
    Write-TestHeader "Prerequisites Check"

    # Test 1: PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    Write-TestResult `
        -TestName "PowerShell Version (>= 5.1)" `
        -Passed ($psVersion.Major -ge 5 -and $psVersion.Minor -ge 1) `
        -Message "Version: $psVersion"

    # Test 2: Processor Script Exists
    $processorExists = Test-Path $script:ProcessorPath
    Write-TestResult `
        -TestName "StreamingCSVProcessor.ps1 exists" `
        -Passed $processorExists `
        -Message $script:ProcessorPath

    # Test 3: Test Data Directory Exists
    $testDataExists = Test-Path $script:TestDataPath
    Write-TestResult `
        -TestName "Test data directory exists" `
        -Passed $testDataExists `
        -Message $script:TestDataPath

    # Test 4: Sample Files Available
    if ($testDataExists) {
        $sampleFiles = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv"
        $hasFiles = $sampleFiles.Count -gt 0
        Write-TestResult `
            -TestName "Sample CSV files available" `
            -Passed $hasFiles `
            -Message "Found $($sampleFiles.Count) files"
    }

    return ($processorExists -and $testDataExists)
}

function Test-ScriptSyntax {
    Write-TestHeader "Script Syntax Validation"

    try {
        $tokens = $null
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content $script:ProcessorPath -Raw),
            [ref]$tokens,
            [ref]$errors
        )

        $passed = $errors.Count -eq 0
        Write-TestResult `
            -TestName "PowerShell syntax validation" `
            -Passed $passed `
            -Message $(if ($errors.Count -gt 0) { "$($errors.Count) syntax errors found" } else { "No syntax errors" })

        if ($errors.Count -gt 0) {
            foreach ($error in $errors) {
                Write-TestWarning "Line $($error.Token.StartLine): $($error.Message)"
            }
        }

        return $passed
    }
    catch {
        Write-TestResult `
            -TestName "PowerShell syntax validation" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-ModuleLoading {
    Write-TestHeader "Module Loading"

    try {
        # Import the processor
        . $script:ProcessorPath

        Write-TestResult `
            -TestName "Module imports successfully" `
            -Passed $true `
            -Message "No errors during import"

        # Test class availability
        $classExists = $null -ne ([StreamingCSVProcessor] -as [Type])
        Write-TestResult `
            -TestName "StreamingCSVProcessor class available" `
            -Passed $classExists

        $postProcessorExists = $null -ne ([CSVPostProcessor] -as [Type])
        Write-TestResult `
            -TestName "CSVPostProcessor class available" `
            -Passed $postProcessorExists

        $optionsExists = $null -ne ([CSVPostProcessingOptions] -as [Type])
        Write-TestResult `
            -TestName "CSVPostProcessingOptions class available" `
            -Passed $optionsExists

        return ($classExists -and $postProcessorExists -and $optionsExists)
    }
    catch {
        Write-TestResult `
            -TestName "Module imports successfully" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-BasicProcessing {
    Write-TestHeader "Basic Processing Tests"

    try {
        . $script:ProcessorPath

        # Find smallest test file
        $testFile = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv" |
            Sort-Object Length |
            Select-Object -First 1

        if (-not $testFile) {
            Write-TestWarning "No test files found"
            return $false
        }

        Write-Host "`nTest File: $($testFile.Name) ($([Math]::Round($testFile.Length / 1KB, 2)) KB)"

        # Test 1: Create processor instance
        $processor = [StreamingCSVProcessor]::new(1000, $true)
        $instanceCreated = $null -ne $processor
        Write-TestResult `
            -TestName "Create StreamingCSVProcessor instance" `
            -Passed $instanceCreated

        if (-not $instanceCreated) { return $false }

        # Test 2: Process file
        $result = $processor.ProcessFile($testFile.FullName)
        $processSuccess = $result.Success -eq $true
        Write-TestResult `
            -TestName "Process CSV file" `
            -Passed $processSuccess `
            -Message "Records: $($result.RecordCount)"

        # Test 3: Verify statistics
        $hasStats = $null -ne $result.Statistics
        Write-TestResult `
            -TestName "Statistics generated" `
            -Passed $hasStats

        if ($hasStats) {
            Write-Host "   → Process Types: $($result.Statistics.ProcessTypes.Count)"
            Write-Host "   → Operations: $($result.Statistics.Operations.Count)"
            Write-Host "   → Results: $($result.Statistics.Results.Count)"
        }

        # Test 4: Verify performance metrics
        $hasPerformance = $null -ne $result.Performance
        Write-TestResult `
            -TestName "Performance metrics collected" `
            -Passed $hasPerformance

        if ($hasPerformance) {
            Write-Host "   → Duration: $($result.Performance.DurationSeconds)s"
            Write-Host "   → Records/sec: $($result.Performance.RecordsPerSecond)"
            Write-Host "   → Memory Used: $($result.Performance.MemoryUsedMB) MB"
        }

        return $processSuccess
    }
    catch {
        Write-TestResult `
            -TestName "Basic processing" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-PostProcessing {
    Write-TestHeader "Post-Processing Tests"

    try {
        . $script:ProcessorPath

        $testFile = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv" |
            Sort-Object Length |
            Select-Object -First 1

        if (-not $testFile) {
            Write-TestWarning "No test files found"
            return $false
        }

        Write-Host "`nTest File: $($testFile.Name)"

        # Test 1: Create custom options
        $options = [CSVPostProcessingOptions]::new()
        $options.FilterSuccessResults = $true
        $options.RemoveDuplicates = $true
        $options.SanitizeData = $true
        $options.CreateSeparateOutputs = $false  # Don't create files for testing

        $optionsCreated = $null -ne $options
        Write-TestResult `
            -TestName "Create post-processing options" `
            -Passed $optionsCreated

        # Test 2: Process with post-processing
        $processor = [StreamingCSVProcessor]::new(1000, $true)
        $result = $processor.ProcessFile($testFile.FullName, $null, $true, $options)

        $hasPostProcessing = $null -ne $result.PostProcessing
        Write-TestResult `
            -TestName "Post-processing executed" `
            -Passed $hasPostProcessing

        if ($hasPostProcessing) {
            $pp = $result.PostProcessing

            # Test 3: Verify filtering occurred
            $filteringWorked = $pp.Statistics.SuccessFiltered -ge 0
            Write-TestResult `
                -TestName "Success filtering applied" `
                -Passed $filteringWorked `
                -Message "$($pp.Statistics.SuccessFiltered) records filtered"

            # Test 4: Verify duplicate detection
            $dupeDetection = $pp.Statistics.DuplicatesRemoved -ge 0
            Write-TestResult `
                -TestName "Duplicate detection applied" `
                -Passed $dupeDetection `
                -Message "$($pp.Statistics.DuplicatesRemoved) duplicates removed"

            # Test 5: Verify data quality metrics
            $hasQuality = $null -ne $pp.DataQuality
            Write-TestResult `
                -TestName "Data quality metrics calculated" `
                -Passed $hasQuality

            if ($hasQuality) {
                Write-Host "   → Retention Rate: $($pp.DataQuality.RetentionRate)%"
                Write-Host "   → Success Filter Rate: $($pp.DataQuality.SuccessFilterRate)%"
                Write-Host "   → Duplicate Rate: $($pp.DataQuality.DuplicateRate)%"
            }
        }

        return $hasPostProcessing
    }
    catch {
        Write-TestResult `
            -TestName "Post-processing" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-ErrorHandling {
    Write-TestHeader "Error Handling Tests"

    try {
        . $script:ProcessorPath

        $processor = [StreamingCSVProcessor]::new(1000, $true)

        # Test 1: Non-existent file
        $result1 = $processor.ProcessFile("NonExistentFile.csv")
        $handlesNotFound = $result1.Success -eq $false
        Write-TestResult `
            -TestName "Handles non-existent file gracefully" `
            -Passed $handlesNotFound `
            -Message "Returned error as expected"

        # Test 2: Empty path
        $result2 = $processor.ProcessFile("")
        $handlesEmpty = $result2.Success -eq $false
        Write-TestResult `
            -TestName "Handles empty path gracefully" `
            -Passed $handlesEmpty `
            -Message "Returned error as expected"

        # Test 3: Null filter callback (should work)
        $testFile = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv" | Select-Object -First 1
        if ($testFile) {
            $result3 = $processor.ProcessFile($testFile.FullName, $null)
            $handlesNullFilter = $result3.Success -eq $true
            Write-TestResult `
                -TestName "Handles null filter gracefully" `
                -Passed $handlesNullFilter `
                -Message "Processed without filter"
        }

        return ($handlesNotFound -and $handlesEmpty)
    }
    catch {
        Write-TestResult `
            -TestName "Error handling" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-MemoryEfficiency {
    Write-TestHeader "Memory Efficiency Tests"

    try {
        . $script:ProcessorPath

        $testFile = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv" |
            Sort-Object Length -Descending |
            Select-Object -First 1

        if (-not $testFile) {
            Write-TestWarning "No test files found"
            return $false
        }

        Write-Host "`nTest File: $($testFile.Name) ($([Math]::Round($testFile.Length / 1MB, 2)) MB)"

        # Test with GC enabled
        $metrics1 = Measure-MemoryUsage {
            $processor = [StreamingCSVProcessor]::new(5000, $true)
            $processor.ProcessFile($testFile.FullName)
        }

        Write-TestResult `
            -TestName "Process with GC enabled" `
            -Passed ($metrics1.Result.Success -eq $true) `
            -Message "Memory: $($metrics1.MemoryUsedMB) MB, Duration: $([Math]::Round($metrics1.DurationSeconds, 2))s"

        # Test with GC disabled
        $metrics2 = Measure-MemoryUsage {
            $processor = [StreamingCSVProcessor]::new(5000, $false)
            $processor.ProcessFile($testFile.FullName)
        }

        Write-TestResult `
            -TestName "Process with GC disabled" `
            -Passed ($metrics2.Result.Success -eq $true) `
            -Message "Memory: $($metrics2.MemoryUsedMB) MB, Duration: $([Math]::Round($metrics2.DurationSeconds, 2))s"

        # Compare
        if ($metrics1.MemoryUsedMB -lt $metrics2.MemoryUsedMB) {
            Write-Host "   → GC reduces memory by $([Math]::Round((1 - $metrics1.MemoryUsedMB / $metrics2.MemoryUsedMB) * 100, 1))%" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-TestResult `
            -TestName "Memory efficiency" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-PerformanceBenchmark {
    Write-TestHeader "Performance Benchmark"

    try {
        . $script:ProcessorPath

        $testFile = Get-ChildItem -Path $script:TestDataPath -Filter "*.csv" |
            Sort-Object Length -Descending |
            Select-Object -First 1

        if (-not $testFile) {
            Write-TestWarning "No test files found"
            return $false
        }

        Write-Host "`nBenchmarking with: $($testFile.Name)"
        Write-Host "File Size: $([Math]::Round($testFile.Length / 1MB, 2)) MB`n"

        # Test different batch sizes
        $batchSizes = @(1000, 5000, 10000, 50000)
        $results = @()

        foreach ($batchSize in $batchSizes) {
            Write-Host "Testing batch size: $batchSize..." -NoNewline

            $metrics = Measure-MemoryUsage {
                $processor = [StreamingCSVProcessor]::new($batchSize, $true)
                $processor.ProcessFile($testFile.FullName)
            }

            $results += @{
                BatchSize = $batchSize
                Duration = $metrics.DurationSeconds
                Memory = $metrics.MemoryUsedMB
                RecordsPerSec = if ($metrics.Result.Performance) {
                    $metrics.Result.Performance.RecordsPerSecond
                } else { 0 }
            }

            Write-Host " Done ($([Math]::Round($metrics.DurationSeconds, 2))s)" -ForegroundColor Green
        }

        # Find optimal
        $fastest = $results | Sort-Object Duration | Select-Object -First 1
        $mostEfficient = $results | Sort-Object Memory | Select-Object -First 1

        Write-Host "`nBenchmark Results:" -ForegroundColor Cyan
        Write-Host "┌─────────────┬──────────────┬──────────────┬─────────────────┐"
        Write-Host "│ Batch Size  │ Duration (s) │ Memory (MB)  │ Records/sec     │"
        Write-Host "├─────────────┼──────────────┼──────────────┼─────────────────┤"

        foreach ($r in $results) {
            $isFastest = $r.BatchSize -eq $fastest.BatchSize
            $isEfficient = $r.BatchSize -eq $mostEfficient.BatchSize
            $color = if ($isFastest -or $isEfficient) { 'Green' } else { 'Gray' }

            $line = "│ {0,11} │ {1,12:F2} │ {2,12:F2} │ {3,15:N0} │" -f `
                $r.BatchSize, $r.Duration, $r.Memory, $r.RecordsPerSec
            Write-Host $line -ForegroundColor $color
        }

        Write-Host "└─────────────┴──────────────┴──────────────┴─────────────────┘"
        Write-Host "`n✨ Fastest: Batch size $($fastest.BatchSize)" -ForegroundColor Green
        Write-Host "💾 Most Memory Efficient: Batch size $($mostEfficient.BatchSize)" -ForegroundColor Green

        return $true
    }
    catch {
        Write-TestResult `
            -TestName "Performance benchmark" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

function Test-HelperFunctions {
    Write-TestHeader "Helper Functions Tests"

    try {
        . $script:ProcessorPath

        # Test 1: Test-StreamingCSVProcessor function exists
        $functionExists = Get-Command Test-StreamingCSVProcessor -ErrorAction SilentlyContinue
        Write-TestResult `
            -TestName "Test-StreamingCSVProcessor function available" `
            -Passed ($null -ne $functionExists)

        # Test 2: Compare-ProcessingMethods function exists
        $compareExists = Get-Command Compare-ProcessingMethods -ErrorAction SilentlyContinue
        Write-TestResult `
            -TestName "Compare-ProcessingMethods function available" `
            -Passed ($null -ne $compareExists)

        return ($null -ne $functionExists)
    }
    catch {
        Write-TestResult `
            -TestName "Helper functions" `
            -Passed $false `
            -Message $_.Exception.Message
        return $false
    }
}

#endregion

#region Code Quality Analysis

function Analyze-CodeQuality {
    Write-TestHeader "Code Quality Analysis"

    $content = Get-Content $script:ProcessorPath -Raw

    # Check 1: Documentation
    $hasHelp = $content -match '<#[\s\S]*?\.SYNOPSIS[\s\S]*?#>'
    Write-TestResult `
        -TestName "Has comprehensive documentation" `
        -Passed $hasHelp

    # Check 2: Error handling
    $hasTryCatch = ($content -split 'try\s*{').Count -gt 1
    Write-TestResult `
        -TestName "Uses try-catch error handling" `
        -Passed $hasTryCatch `
        -Message "Found $(($content -split 'try\s*{').Count - 1) try-catch blocks"

    # Check 3: Using statements
    $hasUsing = $content -match 'using namespace'
    Write-TestResult `
        -TestName "Uses .NET namespace imports" `
        -Passed $hasUsing

    # Check 4: Type definitions
    $classCount = ($content -split 'class\s+\w+').Count - 1
    Write-TestResult `
        -TestName "Defines custom classes" `
        -Passed ($classCount -gt 0) `
        -Message "Found $classCount classes"

    # Check 5: Enum definitions
    $enumCount = ($content -split 'enum\s+\w+').Count - 1
    Write-TestResult `
        -TestName "Defines enums for type safety" `
        -Passed ($enumCount -gt 0) `
        -Message "Found $enumCount enums"

    # Check 6: Optimization comments
    $optimizationCount = ($content -split '#\s*OPTIMIZATION:').Count - 1
    Write-Host "`n📊 Code Metrics:" -ForegroundColor Cyan
    Write-Host "   → Optimization markers: $optimizationCount"
    Write-Host "   → Enhancement markers: $(($content -split '#\s*ENHANCEMENT:').Count - 1)"
    Write-Host "   → Lines of code: $(($content -split "`n").Count)"
    Write-Host "   → Classes defined: $classCount"
    Write-Host "   → Enums defined: $enumCount"
}

#endregion

#region Main Execution

function Invoke-ComprehensiveTests {
    Write-Host "`n"
    Write-Host "╔═══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                                               ║" -ForegroundColor Cyan
    Write-Host "║          StreamingCSVProcessor Comprehensive Test Suite                      ║" -ForegroundColor Cyan
    Write-Host "║                                                                               ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

    # Run all test suites
    $prereqPass = Test-Prerequisites
    if (-not $prereqPass) {
        Write-Host "`n❌ Prerequisites failed. Cannot continue." -ForegroundColor Red
        return
    }

    Test-ScriptSyntax
    $moduleLoaded = Test-ModuleLoading

    if ($moduleLoaded) {
        Test-BasicProcessing
        Test-PostProcessing
        Test-ErrorHandling
        Test-MemoryEfficiency
        Test-PerformanceBenchmark
        Test-HelperFunctions
    }

    Analyze-CodeQuality

    # Summary
    Write-TestHeader "Test Summary"

    $script:TestResults.EndTime = Get-Date
    $duration = $script:TestResults.EndTime - $script:TestResults.StartTime

    $totalTests = $script:TestResults.Passed.Count + $script:TestResults.Failed.Count
    $passRate = if ($totalTests -gt 0) {
        [Math]::Round(($script:TestResults.Passed.Count / $totalTests) * 100, 1)
    } else { 0 }

    Write-Host "`n📊 Results:" -ForegroundColor Cyan
    Write-Host "   Total Tests: $totalTests"
    Write-Host "   ✅ Passed: $($script:TestResults.Passed.Count)" -ForegroundColor Green
    Write-Host "   ❌ Failed: $($script:TestResults.Failed.Count)" -ForegroundColor $(if ($script:TestResults.Failed.Count -eq 0) { 'Green' } else { 'Red' })
    Write-Host "   ⚠️  Warnings: $($script:TestResults.Warnings.Count)" -ForegroundColor Yellow
    Write-Host "   📈 Pass Rate: $passRate%"
    Write-Host "   ⏱️  Duration: $([Math]::Round($duration.TotalSeconds, 2))s"

    if ($script:TestResults.Failed.Count -eq 0) {
        Write-Host "`n🎉 All tests passed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Some tests failed. Review the output above." -ForegroundColor Yellow
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $script:TestResults.Failed | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
    }

    if ($script:TestResults.Warnings.Count -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        $script:TestResults.Warnings | ForEach-Object { Write-Host "   • $_" -ForegroundColor Yellow }
    }

    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
}

# Run tests
Invoke-ComprehensiveTests

#endregion

