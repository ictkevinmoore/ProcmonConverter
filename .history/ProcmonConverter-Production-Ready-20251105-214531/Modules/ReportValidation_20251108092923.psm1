<#
.SYNOPSIS
    Validation module for Professional Report Generator

.DESCRIPTION
    Provides comprehensive input validation, data validation, and security checks
    for the report generation process.

.NOTES
    Version: 1.0
    Date: November 8, 2025
#>

using namespace System.Collections.Generic
using namespace System.Text.RegularExpressions

class ValidationResult {
    [bool]$IsValid
    [List[string]]$Errors
    [List[string]]$Warnings
    [hashtable]$ValidatedData

    ValidationResult() {
        $this.IsValid = $true
        $this.Errors = [List[string]]::new()
        $this.Warnings = [List[string]]::new()
        $this.ValidatedData = @{}
    }

    [void]AddError([string]$message) {
        $this.Errors.Add($message)
        $this.IsValid = $false
    }

    [void]AddWarning([string]$message) {
        $this.Warnings.Add($message)
    }

    [void]SetValidatedData([hashtable]$data) {
        $this.ValidatedData = $data.Clone()
    }

    [hashtable]ToHashtable() {
        return @{
            IsValid = $this.IsValid
            Errors = $this.Errors.ToArray()
            Warnings = $this.Warnings.ToArray()
            ValidatedData = $this.ValidatedData
        }
    }
}

class ReportValidator {
    [hashtable]$ValidationRules
    [List[string]]$SecurityPatterns

    ReportValidator() {
        $this.InitializeValidationRules()
        $this.InitializeSecurityPatterns()
    }

    [void]InitializeValidationRules() {
        $this.ValidationRules = @{
            # DataObject validation rules
            DataObject = @{
                RequiredProperties = @('Events', 'TotalRecords', 'Summary')
                EventsMaxCount = 100000
                TotalRecordsMin = 0
                SummaryRequiredKeys = @('ProcessTypes', 'Operations')
            }

            # SessionInfo validation rules
            SessionInfo = @{
                RequiredProperties = @('SessionId', 'Version', 'FilesProcessed', 'InputDirectory', 'StartTime')
                SessionIdPattern = '^[a-zA-Z0-9_-]{1,50}$'
                VersionPattern = '^\d+\.\d+(\.\d+)?$'
                FilesProcessedMin = 0
                InputDirectoryExists = $true
            }

            # File path validation rules
            FilePath = @{
                MaxLength = 260
                AllowedExtensions = @('.html', '.htm', '.json', '.xml', '.pdf')
                DisallowedChars = @('<', '>', ':', '"', '|', '?', '*')
            }

            # Configuration validation rules
            Configuration = @{
                MaxSampleSizeRange = @(1, 100000)
                TopItemsCountRange = @(1, 100)
                CacheTimeoutMinutesRange = @(1, 1440)
                ValidOutputFormats = @('html', 'json', 'xml', 'pdf')
                ValidThemes = @('auto', 'light', 'dark')
                ValidLogLevels = @('DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL')
            }
        }
    }

    [void]InitializeSecurityPatterns() {
        $this.SecurityPatterns = [List[string]]::new()
        $this.SecurityPatterns.AddRange(@(
            '<script[^>]*>.*?</script>',  # Script tags
            'javascript:',                # JavaScript URLs
            'vbscript:',                  # VBScript URLs
            'data:',                      # Data URLs
            'on\w+\s*=',                 # Event handlers
            '<iframe[^>]*>.*?</iframe>', # Iframes
            '<object[^>]*>.*?</object>', # Object tags
            '<embed[^>]*>.*?</embed>'    # Embed tags
        ))
    }

    [ValidationResult]ValidateDataObject([hashtable]$dataObject) {
        $result = [ValidationResult]::new()

        if ($null -eq $dataObject) {
            $result.AddError("DataObject cannot be null")
            return $result
        }

        # Check required properties
        foreach ($prop in $this.ValidationRules.DataObject.RequiredProperties) {
            if (-not $dataObject.ContainsKey($prop)) {
                $result.AddError("DataObject missing required property: $prop")
            }
        }

        if (-not $result.IsValid) {
            return $result
        }

        # Validate Events
        if ($null -eq $dataObject.Events) {
            $result.AddError("DataObject.Events cannot be null")
        } elseif ($dataObject.Events -isnot [array]) {
            $result.AddError("DataObject.Events must be an array")
        } elseif ($dataObject.Events.Count -gt $this.ValidationRules.DataObject.EventsMaxCount) {
            $result.AddWarning("DataObject.Events count ($($dataObject.Events.Count)) exceeds recommended maximum ($($this.ValidationRules.DataObject.EventsMaxCount))")
        }

        # Validate TotalRecords
        if ($dataObject.TotalRecords -lt $this.ValidationRules.DataObject.TotalRecordsMin) {
            $result.AddError("DataObject.TotalRecords cannot be negative")
        }

        # Validate Summary structure
        if ($null -eq $dataObject.Summary) {
            $result.AddError("DataObject.Summary cannot be null")
        } else {
            foreach ($key in $this.ValidationRules.DataObject.SummaryRequiredKeys) {
                if (-not $dataObject.Summary.ContainsKey($key)) {
                    $result.AddError("DataObject.Summary missing required key: $key")
                }
            }
        }

        # Security check for malicious content
        $securityResult = $this.CheckSecurity($dataObject)
        if (-not $securityResult.IsValid) {
            foreach ($validationError in $securityResult.Errors) {
                $result.AddError($validationError)
            }
        }

        # Set validated data
        if ($result.IsValid) {
            $result.SetValidatedData($dataObject)
        }

        return $result
    }

    [ValidationResult]ValidateSessionInfo([hashtable]$sessionInfo) {
        $result = [ValidationResult]::new()

        if ($null -eq $sessionInfo) {
            $result.AddError("SessionInfo cannot be null")
            return $result
        }

        # Check required properties
        foreach ($prop in $this.ValidationRules.SessionInfo.RequiredProperties) {
            if (-not $sessionInfo.ContainsKey($prop)) {
                $result.AddError("SessionInfo missing required property: $prop")
            }
        }

        if (-not $result.IsValid) {
            return $result
        }

        # Validate SessionId
        if (-not [Regex]::IsMatch($sessionInfo.SessionId, $this.ValidationRules.SessionInfo.SessionIdPattern)) {
            $result.AddError("SessionInfo.SessionId contains invalid characters or is too long")
        }

        # Validate Version
        if (-not [Regex]::IsMatch($sessionInfo.Version, $this.ValidationRules.SessionInfo.VersionPattern)) {
            $result.AddError("SessionInfo.Version must be in format x.y.z")
        }

        # Validate FilesProcessed
        if ($sessionInfo.FilesProcessed -lt $this.ValidationRules.SessionInfo.FilesProcessedMin) {
            $result.AddError("SessionInfo.FilesProcessed cannot be negative")
        }

        # Validate StartTime
        if ($null -eq $sessionInfo.StartTime -or $sessionInfo.StartTime -isnot [DateTime]) {
            $result.AddError("SessionInfo.StartTime must be a valid DateTime object")
        }

        # Validate InputDirectory
        if ($this.ValidationRules.SessionInfo.InputDirectoryExists) {
            if (-not (Test-Path $sessionInfo.InputDirectory)) {
                $result.AddWarning("SessionInfo.InputDirectory does not exist: $($sessionInfo.InputDirectory)")
            }
        }

        # Security check
        $securityResult = $this.CheckSecurity($sessionInfo)
        if (-not $securityResult.IsValid) {
            foreach ($validationError in $securityResult.Errors) {
                $result.AddError($validationError)
            }
        }

        # Set validated data
        if ($result.IsValid) {
            $result.SetValidatedData($sessionInfo)
        }

        return $result
    }

    [ValidationResult]ValidateFilePath([string]$filePath) {
        $result = [ValidationResult]::new()

        if ([string]::IsNullOrEmpty($filePath)) {
            $result.AddError("File path cannot be empty")
            return $result
        }

        # Check length
        if ($filePath.Length -gt $this.ValidationRules.FilePath.MaxLength) {
            $result.AddError("File path is too long (max $($this.ValidationRules.FilePath.MaxLength) characters)")
        }

        # Check for disallowed characters
        foreach ($char in $this.ValidationRules.FilePath.DisallowedChars) {
            if ($filePath.Contains($char)) {
                $result.AddError("File path contains disallowed character: $char")
            }
        }

        # Check file extension
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        if ($extension -notin $this.ValidationRules.FilePath.AllowedExtensions) {
            $result.AddWarning("File extension '$extension' is not in the recommended list: $($this.ValidationRules.FilePath.AllowedExtensions -join ', ')")
        }

        # Check if directory exists
        $directory = [System.IO.Path]::GetDirectoryName($filePath)
        if (-not [string]::IsNullOrEmpty($directory) -and -not (Test-Path $directory)) {
            $result.AddError("Directory does not exist: $directory")
        }

        # Security check for path traversal
        if ($filePath.Contains('..') -or $filePath.Contains('\') -or $filePath.Contains('/')) {
            $normalizedPath = [System.IO.Path]::GetFullPath($filePath)
            $expectedDirectory = [System.IO.Path]::GetFullPath($directory)

            if (-not $normalizedPath.StartsWith($expectedDirectory)) {
                $result.AddError("File path contains path traversal attempt")
            }
        }

        # Set validated data
        if ($result.IsValid) {
            $result.SetValidatedData(@{ FilePath = $filePath })
        }

        return $result
    }

    [ValidationResult]ValidateConfiguration([hashtable]$config) {
        $result = [ValidationResult]::new()

        if ($null -eq $config) {
            $result.AddError("Configuration cannot be null")
            return $result
        }

        # Validate MaxSampleSize
        if ($config.ContainsKey('MaxSampleSize')) {
            $value = $config.MaxSampleSize
            $range = $this.ValidationRules.Configuration.MaxSampleSizeRange
            if ($value -lt $range[0] -or $value -gt $range[1]) {
                $result.AddError("MaxSampleSize must be between $($range[0]) and $($range[1])")
            }
        }

        # Validate TopItemsCount
        if ($config.ContainsKey('TopItemsCount')) {
            $value = $config.TopItemsCount
            $range = $this.ValidationRules.Configuration.TopItemsCountRange
            if ($value -lt $range[0] -or $value -gt $range[1]) {
                $result.AddError("TopItemsCount must be between $($range[0]) and $($range[1])")
            }
        }

        # Validate CacheTimeoutMinutes
        if ($config.ContainsKey('CacheTimeoutMinutes')) {
            $value = $config.CacheTimeoutMinutes
            $range = $this.ValidationRules.Configuration.CacheTimeoutMinutesRange
            if ($value -lt $range[0] -or $value -gt $range[1]) {
                $result.AddError("CacheTimeoutMinutes must be between $($range[0]) and $($range[1])")
            }
        }

        # Validate OutputFormat
        if ($config.ContainsKey('OutputFormat')) {
            if ($config.OutputFormat -notin $this.ValidationRules.Configuration.ValidOutputFormats) {
                $result.AddError("OutputFormat must be one of: $($this.ValidationRules.Configuration.ValidOutputFormats -join ', ')")
            }
        }

        # Validate Theme
        if ($config.ContainsKey('Theme')) {
            if ($config.Theme -notin $this.ValidationRules.Configuration.ValidThemes) {
                $result.AddError("Theme must be one of: $($this.ValidationRules.Configuration.ValidThemes -join ', ')")
            }
        }

        # Validate LogLevel
        if ($config.ContainsKey('LogLevel')) {
            if ($config.LogLevel -notin $this.ValidationRules.Configuration.ValidLogLevels) {
                $result.AddError("LogLevel must be one of: $($this.ValidationRules.Configuration.ValidLogLevels -join ', ')")
            }
        }

        # Security check
        $securityResult = $this.CheckSecurity($config)
        if (-not $securityResult.IsValid) {
            foreach ($validationError in $securityResult.Errors) {
                $result.AddError($validationError)
            }
        }

        # Set validated data
        if ($result.IsValid) {
            $result.SetValidatedData($config)
        }

        return $result
    }

    [ValidationResult]CheckSecurity([object]$data) {
        $result = [ValidationResult]::new()

        if ($null -eq $data) {
            return $result
        }

        $jsonData = $data | ConvertTo-Json -Depth 10 -Compress

        foreach ($pattern in $this.SecurityPatterns) {
            if ([Regex]::IsMatch($jsonData, $pattern, [RegexOptions]::IgnoreCase)) {
                $result.AddError("Security violation detected: potential malicious content matching pattern '$pattern'")
            }
        }

        # Additional security checks
        if ($jsonData.Contains('<script') -or $jsonData.Contains('javascript:') -or $jsonData.Contains('vbscript:')) {
            $result.AddError("Security violation: potentially dangerous script content detected")
        }

        return $result
    }

    [ValidationResult]ValidateAll([hashtable]$dataObject, [hashtable]$sessionInfo, [string]$outputPath, [hashtable]$config) {
        $result = [ValidationResult]::new()

        # Validate DataObject
        $dataResult = $this.ValidateDataObject($dataObject)
        if (-not $dataResult.IsValid) {
            foreach ($error in $dataResult.Errors) {
                $result.AddError("DataObject: $error")
            }
        }
        foreach ($warning in $dataResult.Warnings) {
            $result.AddWarning("DataObject: $warning")
        }

        # Validate SessionInfo
        $sessionResult = $this.ValidateSessionInfo($sessionInfo)
        if (-not $sessionResult.IsValid) {
            foreach ($error in $sessionResult.Errors) {
                $result.AddError("SessionInfo: $error")
            }
        }
        foreach ($warning in $sessionResult.Warnings) {
            $result.AddWarning("SessionInfo: $warning")
        }

        # Validate OutputPath
        $pathResult = $this.ValidateFilePath($outputPath)
        if (-not $pathResult.IsValid) {
            foreach ($error in $pathResult.Errors) {
                $result.AddError("OutputPath: $error")
            }
        }
        foreach ($warning in $pathResult.Warnings) {
            $result.AddWarning("OutputPath: $warning")
        }

        # Validate Configuration
        $configResult = $this.ValidateConfiguration($config)
        if (-not $configResult.IsValid) {
            foreach ($error in $configResult.Errors) {
                $result.AddError("Configuration: $error")
            }
        }

        # Set validated data
        if ($result.IsValid) {
            $result.SetValidatedData(@{
                DataObject = $dataResult.ValidatedData
                SessionInfo = $sessionResult.ValidatedData
                OutputPath = $pathResult.ValidatedData.FilePath
                Configuration = $configResult.ValidatedData
            })
        }

        return $result
    }
}

# Module functions
function New-ReportValidator {
    <#
    .SYNOPSIS
        Creates a new ReportValidator instance

    .EXAMPLE
        $validator = New-ReportValidator
    #>
    [CmdletBinding()]
    param()

    return [ReportValidator]::new()
}

function Test-DataObject {
    <#
    .SYNOPSIS
        Validates a data object

    .PARAMETER DataObject
        The data object to validate

    .EXAMPLE
        $result = Test-DataObject -DataObject $data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject
    )

    $validator = New-ReportValidator
    $result = $validator.ValidateDataObject($DataObject)
    return $result.IsValid
}

function Test-SessionInfo {
    <#
    .SYNOPSIS
        Validates session information

    .PARAMETER SessionInfo
        The session info to validate

    .EXAMPLE
        $result = Test-SessionInfo -SessionInfo $session
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo
    )

    $validator = New-ReportValidator
    $result = $validator.ValidateSessionInfo($SessionInfo)
    return $result.IsValid
}

function Test-ReportInputs {
    <#
    .SYNOPSIS
        Validates all report generation inputs

    .PARAMETER DataObject
        The data object

    .PARAMETER SessionInfo
        The session information

    .PARAMETER OutputPath
        The output file path

    .PARAMETER Config
        The configuration

    .EXAMPLE
        $result = Test-ReportInputs -DataObject $data -SessionInfo $session -OutputPath ".\report.html" -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [hashtable]$Config = @{}
    )

    $validator = New-ReportValidator
    $result = $validator.ValidateAll($DataObject, $SessionInfo, $OutputPath, $Config)
    return $result.ToHashtable()
}

function ConvertTo-SafeHTML {
    <#
    .SYNOPSIS
        HTML-encodes user input to prevent XSS attacks

    .PARAMETER Text
        The text to HTML-encode

    .EXAMPLE
        $safeText = ConvertTo-SafeHTML -Text '<script>alert("XSS")</script>'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Text = ""
    )

    if ([string]::IsNullOrEmpty($Text)) {
        return ""
    }

    return [System.Web.HttpUtility]::HtmlEncode($Text)
}

# Export module members
Export-ModuleMember -Function @(
    'New-ReportValidator',
    'Test-DataObject',
    'Test-SessionInfo',
    'Test-ReportInputs',
    'ConvertTo-SafeHTML'
) -Variable @() -Alias @()

