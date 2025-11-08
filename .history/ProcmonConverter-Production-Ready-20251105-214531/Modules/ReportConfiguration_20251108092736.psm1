<#
.SYNOPSIS
    Configuration management module for Professional Report Generator

.DESCRIPTION
    Handles configuration loading, validation, and management for the report generator.
    Supports multiple configuration sources and provides default values.

.NOTES
    Version: 1.0
    Date: November 8, 2025
#>

using namespace System.Collections.Generic

class ReportConfiguration {
    [hashtable]$DefaultConfig
    [hashtable]$UserConfig
    [hashtable]$MergedConfig
    [string]$ConfigPath
    [List[string]]$ValidationErrors

    ReportConfiguration() {
        $this.InitializeDefaults()
        $this.ValidationErrors = [List[string]]::new()
    }

    [void]InitializeDefaults() {
        $this.DefaultConfig = @{
            # Performance settings
            MaxSampleSize = 5000
            TopItemsCount = 15
            EnableCaching = $true
            CacheTimeoutMinutes = 30

            # Output settings
            OutputFormat = 'html'
            IncludeRawData = $false
            CompressOutput = $false
            Theme = 'auto'

            # Chart settings
            ChartConfig = @{
                Width = 400
                Height = 300
                ColorScheme = 'professional'
                Animation = $true
                Responsive = $true
            }

            # Security settings
            EnableSecurityHeaders = $true
            SanitizeHtml = $true
            ValidateInputs = $true

            # Logging settings
            LogLevel = 'INFO'
            LogToFile = $true
            LogPath = $null

            # Analytics settings
            EnableAnalytics = $true
            AnalyticsDepth = 'Standard'
            RiskThreshold = 0.7

            # UI settings
            PageLength = 25
            LengthMenu = @(10, 25, 50, 100, -1)
            EnableSearch = $true
            EnableExport = $true
        }
    }

    [void]LoadConfiguration([string]$configPath) {
        $this.ConfigPath = $configPath

        if ([string]::IsNullOrEmpty($configPath)) {
            $this.MergedConfig = $this.DefaultConfig.Clone()
            return
        }

        try {
            if (Test-Path $configPath) {
                $fileConfig = $this.LoadConfigFile($configPath)
                $this.UserConfig = $fileConfig
                $this.MergedConfig = $this.MergeConfigurations($this.DefaultConfig, $fileConfig)
            } else {
                Write-Warning "Configuration file not found: $configPath. Using defaults."
                $this.MergedConfig = $this.DefaultConfig.Clone()
            }
        }
        catch {
            Write-Error "Failed to load configuration: $($_.Exception.Message)"
            $this.MergedConfig = $this.DefaultConfig.Clone()
        }
    }

    [hashtable]LoadConfigFile([string]$path) {
        $extension = [System.IO.Path]::GetExtension($path).ToLower()

        switch ($extension) {
            '.json' { return Get-Content $path -Raw | ConvertFrom-Json -AsHashtable }
            '.psd1' { return Import-PowerShellDataFile $path }
            '.xml' {
                $xml = [xml](Get-Content $path -Raw)
                return $this.ConvertXmlToHashtable($xml)
            }
            default {
                throw "Unsupported configuration file format: $extension"
            }
        }
    }

    [hashtable]MergeConfigurations([hashtable]$base, [hashtable]$override) {
        $result = $base.Clone()

        foreach ($key in $override.Keys) {
            if ($result.ContainsKey($key)) {
                if ($result[$key] -is [hashtable] -and $override[$key] -is [hashtable]) {
                    $result[$key] = $this.MergeConfigurations($result[$key], $override[$key])
                } else {
                    $result[$key] = $override[$key]
                }
            } else {
                $result[$key] = $override[$key]
            }
        }

        return $result
    }

    [hashtable]ConvertXmlToHashtable([xml]$xml) {
        $result = @{}

        foreach ($child in $xml.configuration.ChildNodes) {
            if ($child -is [System.Xml.XmlElement]) {
                $result[$child.Name] = $this.ConvertXmlElementToValue($child)
            }
        }

        return $result
    }

    [object]ConvertXmlElementToValue([System.Xml.XmlElement]$element) {
        if ($element.HasChildNodes -and $element.ChildNodes.Count -eq 1 -and $element.FirstChild -is [System.Xml.XmlText]) {
            # Simple value
            return $element.InnerText
        } elseif ($element.HasChildNodes) {
            # Complex object
            $result = @{}
            foreach ($child in $element.ChildNodes) {
                if ($child -is [System.Xml.XmlElement]) {
                    $result[$child.Name] = $this.ConvertXmlElementToValue($child)
                }
            }
            return $result
        }

        return $null
    }

    [bool]ValidateConfiguration() {
        $this.ValidationErrors.Clear()

        # Validate MaxSampleSize
        if ($this.MergedConfig.MaxSampleSize -le 0) {
            $this.ValidationErrors.Add("MaxSampleSize must be greater than 0")
        }

        # Validate TopItemsCount
        if ($this.MergedConfig.TopItemsCount -le 0) {
            $this.ValidationErrors.Add("TopItemsCount must be greater than 0")
        }

        # Validate OutputFormat
        $validFormats = @('html', 'json', 'xml', 'pdf')
        if ($this.MergedConfig.OutputFormat -notin $validFormats) {
            $this.ValidationErrors.Add("OutputFormat must be one of: $($validFormats -join ', ')")
        }

        # Validate Theme
        $validThemes = @('auto', 'light', 'dark')
        if ($this.MergedConfig.Theme -notin $validThemes) {
            $this.ValidationErrors.Add("Theme must be one of: $($validThemes -join ', ')")
        }

        # Validate LogLevel
        $validLogLevels = @('DEBUG', 'INFO', 'WARNING', 'ERROR')
        if ($this.MergedConfig.LogLevel -notin $validLogLevels) {
            $this.ValidationErrors.Add("LogLevel must be one of: $($validLogLevels -join ', ')")
        }

        return $this.ValidationErrors.Count -eq 0
    }

    [hashtable]GetConfiguration() {
        return $this.MergedConfig
    }

    [object]GetValue([string]$key) {
        return $this.MergedConfig[$key]
    }

    [void]SetValue([string]$key, [object]$value) {
        $this.MergedConfig[$key] = $value
    }

    [string[]]GetValidationErrors() {
        return $this.ValidationErrors.ToArray()
    }

    [void]SaveConfiguration([string]$path) {
        if ([string]::IsNullOrEmpty($path)) {
            $path = $this.ConfigPath
        }

        $extension = [System.IO.Path]::GetExtension($path).ToLower()

        switch ($extension) {
            '.json' {
                $this.MergedConfig | ConvertTo-Json -Depth 10 | Out-File $path -Encoding UTF8
            }
            '.psd1' {
                # Convert to PSD1 format
                $psd1Content = $this.ConvertToPsd1Format($this.MergedConfig)
                $psd1Content | Out-File $path -Encoding UTF8
            }
            default {
                throw "Unsupported configuration save format: $extension"
            }
        }
    }

    [string]ConvertToPsd1Format([hashtable]$config) {
        $lines = @()
        $lines += '@{'

        foreach ($key in $config.Keys) {
            $value = $config[$key]
            $valueString = $this.ConvertValueToPsd1String($value)
            $lines += "    $key = $valueString"
        }

        $lines += '}'
        return $lines -join "`n"
    }

    [string]ConvertValueToPsd1String([object]$value) {
        if ($value -is [string]) {
            return "'$value'"
        } elseif ($value -is [int] -or $value -is [double] -or $value -is [bool]) {
            return $value.ToString()
        } elseif ($value -is [array]) {
            $elements = $value | ForEach-Object { $this.ConvertValueToPsd1String($_) }
            return "@($($elements -join ', '))"
        } elseif ($value -is [hashtable]) {
            $pairs = @()
            foreach ($k in $value.Keys) {
                $v = $this.ConvertValueToPsd1String($value[$k])
                $pairs += "$k = $v"
            }
            return "@{$($pairs -join '; ')}"
        } else {
            return "'$($value.ToString())'"
        }
    }
}

# Module functions
function New-ReportConfiguration {
    <#
    .SYNOPSIS
        Creates a new ReportConfiguration instance

    .PARAMETER ConfigPath
        Path to configuration file (optional)

    .EXAMPLE
        $config = New-ReportConfiguration -ConfigPath ".\config\report-config.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )

    $config = [ReportConfiguration]::new()
    $config.LoadConfiguration($ConfigPath)

    if (-not $config.ValidateConfiguration()) {
        $errors = $config.GetValidationErrors()
        Write-Warning "Configuration validation failed:"
        $errors | ForEach-Object { Write-Warning "  - $_" }
    }

    return $config
}

function Get-DefaultReportConfig {
    <#
    .SYNOPSIS
        Gets the default report configuration

    .EXAMPLE
        $defaults = Get-DefaultReportConfig
    #>
    [CmdletBinding()]
    param()

    $config = [ReportConfiguration]::new()
    return $config.GetConfiguration()
}

# Export module members
Export-ModuleMember -Function @(
    'New-ReportConfiguration',
    'Get-DefaultReportConfig'
) -Variable @() -Alias @()
