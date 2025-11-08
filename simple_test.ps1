. ".\ProcmonConverter-Production-Ready-20251105-214531\Generate-Professional-Report.ps1"

$dataObject = @{
    Events = @()
    TotalRecords = 0
    Summary = @{
        ProcessTypes = @{}
        Operations = @{}
    }
}

$sessionInfo = @{
    SessionId = "SIMPLE-TEST"
    Version = "1.0"
    FilesProcessed = 0
    InputDirectory = "."
    StartTime = [System.DateTime]::Now
}

try {
    New-ProfessionalReport -DataObject $dataObject -OutputPath "simple-report.html" -SessionInfo $sessionInfo -Verbose
    Write-Host "Report generation completed."
} catch {
    Write-Host "An error occurred during report generation: $_"
}

