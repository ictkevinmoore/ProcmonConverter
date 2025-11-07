# Configuration Loader Module for Procmon Analysis Suite
# Handles loading and merging of configuration files

#Requires -Version 7.2

function Get-ProcmonConfig {
    <#
    .SYNOPSIS
        Loads and merges Procmon Analysis configuration

    .PARAMETER ProfileName
        Configuration profile to load (Default, HighPerformance, LowMemory, Enterprise, etc.)

    .PARAMETER ConfigPath
        Path to configuration directory (default: Config)

    .EXAMPLE
        $config = Get-ProcmonConfig -ProfileName "Enterprise"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'HighPerformance', 'LowMemory', 'Enterprise', 'Development', 'Testing', 'Production', 'TestProfile')]
        [string]$ProfileName = 'Default',

        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = 'Config'
    )

    try {
        # Load main configuration
        $mainConfigFile = Join-Path $ConfigPath "ProcmonAnalysis.Config.psd1"
        if (-not (Test-Path $mainConfigFile)) {
            throw "Main configuration file not found: $mainConfigFile"
        }
        $mainConfig = Import-PowerShellDataFile -Path $mainConfigFile

        # Load profile configurations
        $profileConfigFile = Join-Path $ConfigPath "ProcmonAnalysis.Profiles.psd1"
        if (-not (Test-Path $profileConfigFile)) {
            throw "Profile configuration file not found: $profileConfigFile"
        }
        $profileConfigs = Import-PowerShellDataFile -Path $profileConfigFile

        # Load pattern configurations
        $patternConfigFile = Join-Path $ConfigPath "ProcmonAnalysis.Patterns.psd1"
        if (-not (Test-Path $patternConfigFile)) {
            throw "Pattern configuration file not found: $patternConfigFile"
        }
        $patternConfig = Import-PowerShellDataFile -Path $patternConfigFile

        # Merge profile-specific settings with main config
        $mergedConfig = Merge-Configuration -BaseConfig $mainConfig -ProfileConfig $profileConfigs[$ProfileName]

        # Add patterns to merged configuration
        $mergedConfig.Patterns = $patternConfig

        # Add runtime metadata
        $mergedConfig.Runtime = @{
            LoadedProfile = $ProfileName
            LoadedAt = [DateTime]::UtcNow
            ConfigPath = $ConfigPath
            SessionId = (Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')
        }

        # Validate configuration
        Test-ConfigurationIntegrity -Config $mergedConfig

        return $mergedConfig
    }
    catch {
        Write-Error "Failed to load configuration: $($_.Exception.Message)"
        throw
    }
}

function Merge-Configuration {
    <#
    .SYNOPSIS
        Deep merges profile configuration with base configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BaseConfig,

        [Parameter(Mandatory = $false)]
        [hashtable]$ProfileConfig = @{}
    )

    # Create deep copy of base configuration
    $mergedConfig = Get-DeepClone -InputObject $BaseConfig

    # Recursively merge profile settings
    foreach ($key in $ProfileConfig.Keys) {
        if ($mergedConfig.ContainsKey($key)) {
            if ($mergedConfig[$key] -is [hashtable] -and $ProfileConfig[$key] -is [hashtable]) {
                # Recursively merge hashtables
                $mergedConfig[$key] = Merge-Hashtables -Base $mergedConfig[$key] -Override $ProfileConfig[$key]
            }
            else {
                # Override primitive values
                $mergedConfig[$key] = $ProfileConfig[$key]
            }
        }
        else {
            # Add new keys from profile
            $mergedConfig[$key] = $ProfileConfig[$key]
        }
    }

    return $mergedConfig
}

function Merge-Hashtables {
    <#
    .SYNOPSIS
        Recursively merges two hashtables
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,

        [Parameter(Mandatory = $true)]
        [hashtable]$Override
    )

    $merged = $Base.Clone()

    foreach ($key in $Override.Keys) {
        if ($merged.ContainsKey($key)) {
            if ($merged[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
                $merged[$key] = Merge-Hashtables -Base $merged[$key] -Override $Override[$key]
            }
            else {
                $merged[$key] = $Override[$key]
            }
        }
        else {
            $merged[$key] = $Override[$key]
        }
    }

    return $merged
}

function Get-DeepClone {
    <#
    .SYNOPSIS
        Creates a deep clone of a PowerShell object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    if ($InputObject -is [hashtable]) {
        $clone = @{}
        foreach ($key in $InputObject.Keys) {
            $clone[$key] = Get-DeepClone -InputObject $InputObject[$key]
        }
        return $clone
    }
    elseif ($InputObject -is [array]) {
        $clone = @()
        foreach ($item in $InputObject) {
            $clone += Get-DeepClone -InputObject $item
        }
        return $clone
    }
    else {
        return $InputObject
    }
}

function Test-ConfigurationIntegrity {
    <#
    .SYNOPSIS
        Validates configuration integrity and required settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )

    $validationErrors = @()

    # Validate required sections
    $requiredSections = @('Application', 'Processing', 'Memory', 'Directories', 'Logging')
    foreach ($section in $requiredSections) {
        if (-not $Config.ContainsKey($section)) {
            $validationErrors += "Missing required configuration section: $section"
        }
    }

    # Validate processing settings
    if ($Config.Processing) {
        if ($Config.Processing.DefaultBatchSize -le 0) {
            $validationErrors += "DefaultBatchSize must be greater than 0"
        }
        if ($Config.Processing.DefaultMaxFileSize -le 0) {
            $validationErrors += "DefaultMaxFileSize must be greater than 0"
        }
    }

    # Validate memory settings
    if ($Config.Memory) {
        if ($Config.Memory.DefaultThresholdMB -le 0) {
            $validationErrors += "DefaultThresholdMB must be greater than 0"
        }
        if ($Config.Memory.DefaultForceGCThresholdMB -le $Config.Memory.DefaultThresholdMB) {
            $validationErrors += "DefaultForceGCThresholdMB must be greater than DefaultThresholdMB"
        }
    }

    # Validate logging settings
    if ($Config.Logging) {
        $validLevels = @('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')
        if ($Config.Logging.DefaultLevel -notin $validLevels) {
            $validationErrors += "Invalid logging level: $($Config.Logging.DefaultLevel)"
        }
    }

    # Report validation errors
    if ($validationErrors.Count -gt 0) {
        $errorMessage = "Configuration validation failed:`n" + ($validationErrors -join "`n")
        throw $errorMessage
    }

    Write-Verbose "Configuration validation passed successfully"
}

function Test-ProcmonInputSecurity {
    <#
    .SYNOPSIS
        Validates input parameters for security issues
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputDirectory,

        [Parameter(Mandatory = $false)]
        [string]$AllowedBasePath = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$SecurityConfig = @{}
    )

    $validationResults = @{
        IsValid = $true
        Issues = @()
        Warnings = @()
    }

    try {
        # Path traversal protection
        $fullInputPath = [System.IO.Path]::GetFullPath($InputDirectory)
        $fullBasePath = [System.IO.Path]::GetFullPath($AllowedBasePath)

        if (-not $fullInputPath.StartsWith($fullBasePath, [StringComparison]::OrdinalIgnoreCase)) {
            $validationResults.Issues += "Path '$InputDirectory' is outside allowed directory '$AllowedBasePath'"
            $validationResults.IsValid = $false
        }

        # Directory existence check
        if (-not (Test-Path $InputDirectory -PathType Container)) {
            $validationResults.Issues += "Directory '$InputDirectory' does not exist"
            $validationResults.IsValid = $false
        }

        # Path length validation
        if ($SecurityConfig.MaxPathLength -and $fullInputPath.Length -gt $SecurityConfig.MaxPathLength) {
            $validationResults.Issues += "Path length exceeds maximum allowed: $($fullInputPath.Length) > $($SecurityConfig.MaxPathLength)"
            $validationResults.IsValid = $false
        }

        # Check for CSV files
        if ($validationResults.IsValid) {
            $csvFiles = Get-ChildItem -Path $InputDirectory -Filter "*.csv" -File -ErrorAction SilentlyContinue
            if ($csvFiles.Count -eq 0) {
                $validationResults.Issues += "No CSV files found in directory '$InputDirectory'"
                $validationResults.IsValid = $false
            }
            else {
                $validationResults.Warnings += "Found $($csvFiles.Count) CSV files for processing"
            }
        }

        # Check available memory vs batch size requirements
        try {
            $availableMemoryMB = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory / 1KB
            if ($availableMemoryMB -lt 100) {
                $validationResults.Warnings += "Low available memory: $([Math]::Round($availableMemoryMB, 0)) MB"
            }
        }
        catch {
            $validationResults.Warnings += "Could not determine available memory"
        }

    }
    catch {
        $validationResults.Issues += "Security validation error: $($_.Exception.Message)"
        $validationResults.IsValid = $false
    }

    return $validationResults
}

function Test-ContentSafety {
    <#
    .SYNOPSIS
        Validates CSV content for potential security issues
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [hashtable]$SecurityConfig = @{}
    )

    # Check for suspicious patterns that might indicate malicious content
    $suspiciousPatterns = @(
        '=.*\|.*',      # Excel formula injection
        '@.*\+.*',      # Command execution attempts
        '\x00',         # Null bytes
        '[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'  # Control characters
    )

    foreach ($pattern in $suspiciousPatterns) {
        if ($Content -match $pattern) {
            return $false
        }
    }

    # Check field length limits
    if ($SecurityConfig.MaxFieldLength) {
        if ($Content.Length -gt $SecurityConfig.MaxFieldLength) {
            return $false
        }
    }

    return $true
}

function Get-BusinessLogicValidation {
    <#
    .SYNOPSIS
        Validates business logic constraints for parameters
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$BatchSize,

        [Parameter(Mandatory = $true)]
        [int]$MaxFileSize,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    $validationResults = @{
        IsValid = $true
        Issues = @()
        Warnings = @()
        Adjustments = @{}
    }

    # Validate batch size against available memory
    try {
        $availableMemoryMB = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).FreePhysicalMemory / 1KB
        $estimatedMemoryUsagePerRecord = 1KB  # Conservative estimate
        $estimatedBatchMemoryMB = ($BatchSize * $estimatedMemoryUsagePerRecord) / 1MB

        if ($estimatedBatchMemoryMB -gt ($availableMemoryMB * 0.8)) {
            $suggestedBatchSize = [Math]::Max(1000, [int](($availableMemoryMB * 0.5 * 1MB) / $estimatedMemoryUsagePerRecord))
            $validationResults.Warnings += "BatchSize may cause memory pressure. Consider reducing to $suggestedBatchSize"
            $validationResults.Adjustments.SuggestedBatchSize = $suggestedBatchSize
        }
    }
    catch {
        $validationResults.Warnings += "Could not validate memory requirements"
    }

    # Validate file size limits
    if ($MaxFileSize -gt 5000) {
        $validationResults.Warnings += "Large MaxFileSize ($MaxFileSize MB) may impact performance"
    }

    # Check for realistic parameter combinations
    if ($BatchSize -lt 1000 -and $MaxFileSize -gt 1000) {
        $validationResults.Warnings += "Small BatchSize with large MaxFileSize may be inefficient"
    }

    return $validationResults
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ProcmonConfig',
    'Test-ProcmonInputSecurity',
    'Test-ContentSafety',
    'Get-BusinessLogicValidation'
)
