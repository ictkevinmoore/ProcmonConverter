<#
.SYNOPSIS
    Modular HTML Template Engine for Professional Reports

.DESCRIPTION
    Provides template loading, caching, and placeholder replacement functionality
    for generating modular HTML reports using predefined templates.

.NOTES
    Author: AI Assistant
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

using namespace System.Collections.Generic
using namespace System.Text

class TemplateEngine {
    [hashtable]$Templates
    [hashtable]$Cache
    [string]$TemplatePath
    [bool]$EnableCache

    TemplateEngine([string]$templatePath, [bool]$enableCache = $true) {
        $this.Templates = @{}
        $this.Cache = @{}
        $this.TemplatePath = $templatePath
        $this.EnableCache = $enableCache
        $this.InitializeTemplates()
    }

    [void] InitializeTemplates() {
        # Load core templates
        $templateFiles = @{
            'ReportTemplate' = 'ReportTemplate.html'
            'TabContent' = 'TabContent.html'
            'Styles' = 'styles.css'
            'Scripts' = 'scripts.js'
        }

        foreach ($key in $templateFiles.Keys) {
            $templateFile = Join-Path $this.TemplatePath $templateFiles[$key]
            if (Test-Path $templateFile) {
                try {
                    $content = Get-Content -Path $templateFile -Raw -Encoding UTF8
                    $this.Templates[$key] = $content
                    Write-Verbose "Loaded template: $key from $templateFile"
                }
                catch {
                    Write-Warning "Failed to load template $key from $templateFile`: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "Template file not found: $templateFile"
            }
        }
    }

    [string] Render([string]$templateName, [hashtable]$data) {
        if (-not $this.Templates.ContainsKey($templateName)) {
            throw "Template '$templateName' not found. Available templates: $($this.Templates.Keys -join ', ')"
        }

        $template = $this.Templates[$templateName]
        $cacheKey = $this.GetCacheKey($templateName, $data)

        # Check cache first
        if ($this.EnableCache -and $this.Cache.ContainsKey($cacheKey)) {
            return $this.Cache[$cacheKey]
        }

        # Process template with data
        $result = $this.ProcessTemplate($template, $data)

        # Cache result
        if ($this.EnableCache) {
            $this.Cache[$cacheKey] = $result
        }

        return $result
    }

    [string] ProcessTemplate([string]$template, [hashtable]$data) {
        $result = $template

        # Replace simple placeholders {{key}}
        foreach ($key in $data.Keys) {
            $placeholder = "{{$key}}"
            $value = $this.FormatValue($data[$key])
            $result = $result.Replace($placeholder, $value)
        }

        # Handle conditional blocks {{#if condition}}...{{/if}}
        $result = $this.ProcessConditionals($result, $data)

        # Handle loops {{#each items}}...{{/each}}
        $result = $this.ProcessLoops($result, $data)

        return $result
    }

    [string] FormatValue([object]$value) {
        if ($null -eq $value) {
            return ""
        }

        switch ($value.GetType().Name) {
            'String' {
                return [System.Web.HttpUtility]::HtmlEncode($value)
            }
            'Int32' {
                return $value.ToString()
            }
            'Int64' {
                return $value.ToString()
            }
            'Double' {
                return $value.ToString("N2")
            }
            'DateTime' {
                return $value.ToString("yyyy-MM-dd HH:mm:ss")
            }
            'Boolean' {
                return $value.ToString().ToLower()
            }
            'ArrayList' {
                return ($value | ForEach-Object { $this.FormatValue($_) }) -join ','
            }
            'Object[]' {
                return ($value | ForEach-Object { $this.FormatValue($_) }) -join ','
            }
            default {
                return [System.Web.HttpUtility]::HtmlEncode($value.ToString())
            }
        }
    }

    [string] ProcessConditionals([string]$template, [hashtable]$data) {
        $pattern = '{{#if\s+(\w+)}}(.*?){{/if}}'
        $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $evaluator = {
            param($match)
            $condition = $match.Groups[1].Value
            $content = $match.Groups[2].Value

            if ($data.ContainsKey($condition) -and $data[$condition]) {
                return $content
            }
            return ""
        }

        return $regex.Replace($template, $evaluator)
    }

    [string] ProcessLoops([string]$template, [hashtable]$data) {
        $pattern = '{{#each\s+(\w+)}}(.*?){{/each}}'
        $regex = [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

        $evaluator = {
            param($match)
            $arrayName = $match.Groups[1].Value
            $itemTemplate = $match.Groups[2].Value

            if (-not $data.ContainsKey($arrayName)) {
                return ""
            }

            $array = $data[$arrayName]
            if (-not $array -or $array.Count -eq 0) {
                return ""
            }

            $result = ""
            foreach ($item in $array) {
                if ($item -is [hashtable]) {
                    $itemResult = $this.ProcessTemplate($itemTemplate, $item)
                }
                else {
                    # Simple value replacement
                    $itemResult = $itemTemplate.Replace("{{this}}", $this.FormatValue($item))
                }
                $result += $itemResult
            }

            return $result
        }

        return $regex.Replace($template, $evaluator)
    }

    [string] GetCacheKey([string]$templateName, [hashtable]$data) {
        $dataHash = $this.GetHashtableHash($data)
        return "$templateName`_$dataHash"
    }

    [string] GetHashtableHash([hashtable]$data) {
        $sortedKeys = $data.Keys | Sort-Object
        $content = ""
        foreach ($key in $sortedKeys) {
            $content += "$key=$($data[$key]);"
        }
        return Get-StringHash $content
    }

    [void] ClearCache() {
        $this.Cache.Clear()
    }

    [string[]] GetAvailableTemplates() {
        return $this.Templates.Keys
    }

    [bool] TemplateExists([string]$templateName) {
        return $this.Templates.ContainsKey($templateName)
    }
}

function Get-StringHash {
    param([string]$inputString)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($inputString)
    $hash = $sha256.ComputeHash($bytes)
    $sha256.Dispose()

    return [BitConverter]::ToString($hash).Replace("-", "").ToLower()
}

# Export the class and helper functions
Export-ModuleMember -Function Get-StringHash
Export-ModuleMember -Variable TemplateEngine

