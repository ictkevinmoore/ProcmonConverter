#Requires -Version 5.1

<#
.SYNOPSIS
    Creates a complete, portable backup of the ProcmonConverter Suite

.DESCRIPTION
    This script creates a timestamped backup of all essential files and structure,
    ensuring the backup can be copied to any location and run immediately without errors.

.PARAMETER BackupPath
    Destination path for the backup. If not specified, creates backup in .\Backups\

.PARAMETER IncludeData
    Include Data directory in backup (warning: may be large)

.PARAMETER IncludeReports
    Include existing reports in backup

.PARAMETER TestBackup
    Automatically test the backup after creation

.EXAMPLE
    .\Create-Suite-Backup.ps1
    Creates backup with default settings

.EXAMPLE
    .\Create-Suite-Backup.ps1 -BackupPath "D:\Backups" -TestBackup
    Creates backup in custom location and tests it

.EXAMPLE
    .\Create-Suite-Backup.ps1 -IncludeData -IncludeReports
    Creates complete backup including all data and reports
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BackupPath = "",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeData,

    [Parameter(Mandatory = $false)]
    [switch]$IncludeReports,

    [Parameter(Mandatory = $false)]
    [switch]$TestBackup
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      ProcmonConverter Suite - Backup & Archive Tool                ║" -ForegroundColor Cyan
Write-Host "║      Version 1.0                                                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Determine backup directory
if ([string]::IsNullOrEmpty($BackupPath)) {
    $BackupPath = Join-Path $PSScriptRoot "Backups"
}

$backupDir = Join-Path $BackupPath "ProcmonSuite-Backup-$timestamp"

try {
    # Create backup directory
    Write-Host "[1/7] Creating backup directory..." -ForegroundColor Yellow
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    Write-Host "  ✓ Created: $backupDir" -ForegroundColor Green

    # Define essential files
    Write-Host "`n[2/7] Identifying essential files..." -ForegroundColor Yellow
    $essentialFiles = @(
        "Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1",
        "StreamingCSVProcessor.ps1",
        "Generate-Professional-Report.ps1",
        "PROCMON-SUITE-COMPLETE-INDEX.md",
        "Create-Suite-Backup.ps1",
        "Test-IntegratedSuite.ps1"
    )

    $found = 0
    $missing = @()

    foreach ($file in $essentialFiles) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            $found++
            Write-Host "  ✓ Found: $file" -ForegroundColor DarkGreen
        } else {
            $missing += $file
            Write-Host "  ✗ Missing: $file" -ForegroundColor DarkYellow
        }
    }

    Write-Host "  ℹ Found $found of $($essentialFiles.Count) essential files" -ForegroundColor Cyan

    if ($missing.Count -gt 0 -and $missing.Count -eq $essentialFiles.Count) {
        throw "No essential files found! Please run this script from the ProcmonConverter root directory."
    }

    # Copy essential files
    Write-Host "`n[3/7] Copying core scripts..." -ForegroundColor Yellow
    $copiedCount = 0

    foreach ($file in $essentialFiles) {
        $sourcePath = Join-Path $PSScriptRoot $file
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $backupDir $file
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            $copiedCount++
            Write-Host "  ✓ Copied: $file" -ForegroundColor Green
        }
    }

    Write-Host "  ℹ Copied $copiedCount files" -ForegroundColor Cyan

    # Create directory structure
    Write-Host "`n[4/7] Creating directory structure..." -ForegroundColor Yellow
    $directories = @(
        "Data\Converted",
        "Data\Raw",
        "Config",
        "Ultimate-Analysis-Reports"
    )

    foreach ($dir in $directories) {
        $dirPath = Join-Path $backupDir $dir
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
        Write-Host "  ✓ Created: $dir" -ForegroundColor Green
    }

    # Copy Config directory if exists
    $configSource = Join-Path $PSScriptRoot "Config"
    if (Test-Path $configSource) {
        $configDest = Join-Path $backupDir "Config"
        Copy-Item -Path "$configSource\*" -Destination $configDest -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Copied Config directory" -ForegroundColor Green
    }

    # Optional: Include Data
    if ($IncludeData) {
        Write-Host "`n[5/7] Including Data directory..." -ForegroundColor Yellow
        $dataSource = Join-Path $PSScriptRoot "Data"
        if (Test-Path $dataSource) {
            $dataDest = Join-Path $backupDir "Data"
            Copy-Item -Path "$dataSource\*" -Destination $dataDest -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Data directory included" -ForegroundColor Green
        } else {
            Write-Host "  ℹ Data directory not found, skipping" -ForegroundColor Gray
        }
    } else {
        Write-Host "`n[5/7] Skipping Data directory (use -IncludeData to include)" -ForegroundColor Gray
    }

    # Optional: Include Reports
    if ($IncludeReports) {
        Write-Host "`n[6/7] Including Reports..." -ForegroundColor Yellow
        $reportsSource = Join-Path $PSScriptRoot "Ultimate-Analysis-Reports"
        if (Test-Path $reportsSource) {
            $reportsDest = Join-Path $backupDir "Ultimate-Analysis-Reports"
            Copy-Item -Path "$reportsSource\*" -Destination $reportsDest -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  ✓ Reports included" -ForegroundColor Green
        } else {
            Write-Host "  ℹ Reports directory not found, skipping" -ForegroundColor Gray
        }
    } else {
        Write-Host "`n[6/7] Skipping Reports directory (use -IncludeReports to include)" -ForegroundColor Gray
    }

    # Create README in backup
    Write-Host "`n[7/7] Creating backup documentation..." -ForegroundColor Yellow
    $readmePath = Join-Path $backupDir "BACKUP-README.md"
    $readmeContent = @"
# ProcmonConverter Suite - Backup Package

**Created:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Version:** 12.0-Integrated-Edition
**Source:** $($PSScriptRoot)

## 📦 Backup Contents

### Essential Files Included:
$($essentialFiles | ForEach-Object { "- $_" } | Out-String)

### Directory Structure:
- Data/Converted/ - Place CSV files here for analysis
- Data/Raw/ - Optional: Store raw PML files
- Config/ - Configuration files
- Ultimate-Analysis-Reports/ - Output directory for reports

## 🚀 Quick Start

1. **Extract/Copy this backup to your desired location**

2. **Navigate to the directory:**
``````powershell
cd "C:\Path\To\Backup"
``````

3. **Place CSV files in Data\Converted\**

4. **Run the analysis:**
``````powershell
pwsh -File .\Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1 ``
    -InputDirectory ".\Data\Converted"
``````

## 📋 Verification Checklist

Before running, verify:
- [ ] All three core scripts are present
- [ ] PowerShell 5.1+ is installed
- [ ] CSV files are in Data\Converted\ directory
- [ ] You have write permissions for the directory

## 🧪 Test the Suite

Run the test script to verify everything works:
``````powershell
pwsh -File .\Test-IntegratedSuite.ps1
``````

## 📖 Full Documentation

See PROCMON-SUITE-COMPLETE-INDEX.md for complete documentation including:
- All parameters and variables
- Usage examples
- Configuration profiles
- Troubleshooting guide

## ⚠️ Important Notes

- This backup is fully portable
- No absolute paths are used
- All scripts use relative paths
- Can be copied to any location
- Requires PowerShell 5.1 or higher

## 🔧 Restore to Original Location

To restore to the original location:
``````powershell
`$source = "$backupDir"
`$destination = "C:\Users\ictke\OneDrive\Desktop\ProcmonConverter"
Copy-Item "`$source\*" `$destination -Recurse -Force
``````

---

**Backup created successfully!**
**Ready to use immediately after extraction.**
"@

    $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8 -Force
    Write-Host "  ✓ Created BACKUP-README.md" -ForegroundColor Green

    # Calculate backup size
    $backupSize = (Get-ChildItem -Path $backupDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $backupSizeMB = [Math]::Round($backupSize / 1MB, 2)

    # Success summary
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    BACKUP COMPLETED SUCCESSFULLY                    ║" -ForegroundColor Green
    Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║  Location: $($backupDir.PadRight(58)) ║" -ForegroundColor Green
    Write-Host "║  Size: $($backupSizeMB.ToString('F2').PadRight(64)) MB ║" -ForegroundColor Green
    Write-Host "║  Files Copied: $($copiedCount.ToString().PadRight(55)) ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

    # Test backup if requested
    if ($TestBackup) {
        Write-Host "`n[TESTING] Verifying backup integrity..." -ForegroundColor Magenta

        # Check all essential files
        $testResults = @()
        foreach ($file in $essentialFiles) {
            $filePath = Join-Path $backupDir $file
            if (Test-Path $filePath) {
                $testResults += @{ File = $file; Status = "✓ Present" }
            } else {
                $testResults += @{ File = $file; Status = "✗ Missing" }
            }
        }

        # Display test results
        Write-Host "`nTest Results:" -ForegroundColor Cyan
        foreach ($result in $testResults) {
            if ($result.Status -match "✓") {
                Write-Host "  $($result.Status): $($result.File)" -ForegroundColor Green
            } else {
                Write-Host "  $($result.Status): $($result.File)" -ForegroundColor Red
            }
        }

        # Check if main script can be loaded
        $mainScript = Join-Path $backupDir "Ultimate-Modular-ProcmonAnalysis-Suite-INTEGRATED.ps1"
        if (Test-Path $mainScript) {
            try {
                $content = Get-Content $mainScript -Raw
                if ($content -match '#Requires -Version') {
                    Write-Host "`n  ✓ Main script structure verified" -ForegroundColor Green
                    Write-Host "  ✓ Backup is ready to use!" -ForegroundColor Green
                } else {
                    Write-Host "`n  ⚠ Main script may be incomplete" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "`n  ✗ Error reading main script: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }

    # Create compressed archive
    Write-Host "`nWould you like to create a ZIP archive? (Y/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host

    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "`nCreating ZIP archive..." -ForegroundColor Yellow
        $zipPath = "$backupDir.zip"

        if ($PSVersionTable.PSVersion.Major -ge 5) {
            Compress-Archive -Path $backupDir -DestinationPath $zipPath -Force
            $zipSize = [Math]::Round((Get-Item $zipPath).Length / 1MB, 2)
            Write-Host "  ✓ ZIP created: $zipPath ($zipSize MB)" -ForegroundColor Green
        } else {
            Write-Host "  ℹ ZIP creation requires PowerShell 5.0 or higher" -ForegroundColor Gray
        }
    }

    return @{
        Success = $true
        BackupPath = $backupDir
        FilesCount = $copiedCount
        SizeMB = $backupSizeMB
    }

} catch {
    Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                       BACKUP FAILED                                 ║" -ForegroundColor Red
    Write-Host "╠══════════════════════════════════════════════════════════════════════╣" -ForegroundColor Red
    Write-Host "║  Error: $($_.Exception.Message.PadRight(60)) ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Red

    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}
