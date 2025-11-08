<#
.SYNOPSIS
    Data Binding and Validation System for HTML Report Generation

.DESCRIPTION
    Provides type-safe data binding with validation for report data structures.
    Ensures data integrity and provides helpful error messages for missing or invalid data.

.NOTES
    Author: AI Assistant
    Version: 1.0.0
    Requires: PowerShell 5.1+
#>

using namespace System.Collections.Generic

class DataValidationException : Exception {
    [string]$FieldName
    [string]$ExpectedType
    [object]$ActualValue

    DataValidationException([string]$message, [string]$fieldName, [string]$expectedType, [object]$actualValue) : base($message) {
        $this.FieldName = $fieldName
        $this.ExpectedType = $expectedType
        $this.ActualValue = $actualValue
    }
}

class DataBinder {
    [hashtable]$Schemas
    [bool]$StrictMode

    DataBinder([bool]$strictMode = $true) {
        $this.Schemas = @{}
        $this.StrictMode = $strictMode
        $this.InitializeSchemas()
    }

    [void] InitializeSchemas() {
        # Define data schemas for different report sections
        $this.Schemas['SessionInfo'] = @{
            Required = @('SessionId', 'Version', 'FilesProcessed', 'InputDirectory', 'StartTime')
            Types = @{
                'SessionId' = 'String'
                'Version' = 'String'
                'FilesProcessed' = 'Int32'
                'InputDirectory' = 'String'
                'StartTime' = 'DateTime'
            }
            Validators = @{
                'FilesProcessed' = { param($value) $value -ge 0 }
                'SessionId' = { param($value) -not [string]::IsNullOrWhiteSpace($value) }
            }
        }

        $this.Schemas['Summary'] = @{
            Required = @('TotalRecords', 'FilesProcessed', 'UniqueProcesses', 'OperationTypes')
            Types = @{
                'TotalRecords' = 'Int64'
                'FilesProcessed' = 'Int32'
                'UniqueProcesses' = 'Int32'
                'OperationTypes' = 'Int32'
            }
            Validators = @{
                'TotalRecords' = { param($value) $value -ge 0 }
                'FilesProcessed' = { param($value) $value -ge 0 }
                'UniqueProcesses' = { param($value) $value -ge 0 }
                'OperationTypes' = { param($value) $value -ge 0 }
            }
        }

        $this.Schemas['ProcessData'] = @{
            Required = @('Name', 'Count')
            Types = @{
                'Name' = 'String'
                'Count' = 'Int64'
            }
            Validators = @{
                'Count' = { param($value) $value -ge 0 }
                'Name' = { param($value) -not [string]::IsNullOrWhiteSpace($value) }
            }
        }

        $this.Schemas['OperationData'] = @{
            Required = @('Name', 'Count')
            Types = @{
                'Name' = 'String'
                'Count' = 'Int64'
            }
            Validators = @{
                'Count' = { param($value) $value -ge 0 }
                'Name' = { param($value) -not [string]::IsNullOrWhiteSpace($value) }
            }
        }

        $this.Schemas['ChartData'] = @{
            Required = @('Labels', 'Data')
            Types = @{
                'Labels' = 'String'
                'Data' = 'String'
            }
        }

        $this.Schemas['EventData'] = @{
            Required = @('Time', 'ProcessName', 'Operation', 'Path', 'Result')
            Types = @{
                'Time' = 'String'
                'ProcessName' = 'String'
                'Operation' = 'String'
                'Path' = 'String'
                'Result' = 'String'
            }
        }
    }

    [hashtable] BindReportData([hashtable]$rawData) {
        try {
            # Validate and bind session info
            $sessionInfo = $this.BindObject($rawData.SessionInfo, 'SessionInfo')

            # Validate and bind summary data
            $summary = $this.BindObject($rawData.Summary, 'Summary')

            # Process top processes
            $topProcesses = $this.BindArray($rawData.TopProcesses, 'ProcessData')

            # Process top operations
            $topOperations = $this.BindArray($rawData.TopOperations, 'OperationData')

            # Process sample events
            $sampleEvents = $this.BindArray($rawData.SampleEvents, 'EventData')

            # Process chart data
            $processChartData = $this.BindChartData($rawData.ProcessChartData, 'Process')
            $operationChartData = $this.BindChartData($rawData.OperationChartData, 'Operation')

            # Calculate additional metrics
            $insights = $this.CalculateInsights($topProcesses, $topOperations, $summary)

            return @{
                SessionInfo = $sessionInfo
                Summary = $summary
                TopProcesses = $topProcesses
                TopOperations = $topOperations
                SampleEvents = $sampleEvents
                ProcessChartData = $processChartData
                OperationChartData = $operationChartData
                Insights = $insights
                GeneratedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                ComputerName = $env:COMPUTERNAME
            }
        }
        catch {
            throw "Data binding failed: $($_.Exception.Message)"
        }
    }

    [hashtable] BindObject([hashtable]$data, [string]$schemaName) {
        if (-not $this.Schemas.ContainsKey($schemaName)) {
            throw "Unknown schema: $schemaName"
        }

        $schema = $this.Schemas[$schemaName]
        $result = @{}

        # Check required fields
        foreach ($field in $schema.Required) {
            if (-not $data.ContainsKey($field)) {
                throw [DataValidationException]::new(
                    "Required field '$field' is missing",
                    $field,
                    $schema.Types[$field],
                    $null
                )
            }
        }

        # Validate and convert each field
        foreach ($key in $data.Keys) {
            $value = $data[$key]
            $expectedType = $schema.Types[$key]

            if ($expectedType) {
                $convertedValue = $this.ConvertValue($value, $expectedType, $key)
                $result[$key] = $convertedValue

                # Run custom validators
                if ($schema.Validators.ContainsKey($key)) {
                    $validator = $schema.Validators[$key]
                    if (-not (& $validator $convertedValue)) {
                        throw [DataValidationException]::new(
                            "Validation failed for field '$key'",
                            $key,
                            $expectedType,
                            $convertedValue
                        )
                    }
                }
            }
            elseif ($this.StrictMode) {
                Write-Warning "Unknown field '$key' in schema '$schemaName' (strict mode enabled)"
            }
            else {
                $result[$key] = $value
            }
        }

        return $result
    }

    [array] BindArray([array]$data, [string]$schemaName) {
        if (-not $data) {
            return @()
        }

        $result = @()
        for ($i = 0; $i -lt $data.Count; $i++) {
            try {
                if ($data[$i] -is [hashtable]) {
                    $boundItem = $this.BindObject($data[$i], $schemaName)
                }
                else {
                    # Handle simple arrays - use the first available type from schema
                    $schema = $this.Schemas[$schemaName]
                    $typeKey = $schema.Types.Keys | Select-Object -First 1
                    $boundItem = $this.ConvertValue($data[$i], $schema.Types[$typeKey], "Item$i")
                }
                $result += $boundItem
            }
            catch {
                Write-Warning "Failed to bind array item $i`: $($_.Exception.Message)"
                if ($this.StrictMode) {
                    throw
                }
            }
        }

        return $result
    }

    [hashtable] BindChartData([hashtable]$chartData, [string]$chartType) {
        if (-not $chartData) {
            return @{
                Labels = "'No Data'"
                Data = "0"
            }
        }

        $labels = $this.ConvertValue($chartData.Labels, 'String', 'Labels')
        $data = $this.ConvertValue($chartData.Data, 'String', 'Data')

        return @{
            Labels = $labels
            Data = $data
        }
    }

    [object] ConvertValue([object]$value, [string]$targetType, [string]$fieldName) {
        if ($null -eq $value) {
            if ($targetType -eq 'String') {
                return ""
            }
            throw [DataValidationException]::new(
                "Null value not allowed for field '$fieldName'",
                $fieldName,
                $targetType,
                $value
            )
        }

        try {
            switch ($targetType) {
                'String' {
                    return [string]$value
                }
                'Int32' {
                    return [int]$value
                }
                'Int64' {
                    return [long]$value
                }
                'Double' {
                    return [double]$value
                }
                'DateTime' {
                    if ($value -is [DateTime]) {
                        return $value
                    }
                    return [DateTime]::Parse($value)
                }
                'Boolean' {
                    return [bool]$value
                }
                default {
                    return $value
                }
            }
        }
        catch {
            throw [DataValidationException]::new(
                "Cannot convert value to $targetType for field '$fieldName'",
                $fieldName,
                $targetType,
                $value
            )
        }
    }

    [hashtable] CalculateInsights([array]$topProcesses, [array]$topOperations, [hashtable]$summary) {
        $insights = @{
            AverageEventsPerProcess = 0
            TopProcess = $null
            TopOperation = $null
            ProcessPercentage = 0
            TotalTopProcesses = $topProcesses.Count
            TotalTopOperations = $topOperations.Count
        }

        if ($summary.UniqueProcesses -gt 0) {
            $insights.AverageEventsPerProcess = [math]::Round($summary.TotalRecords / $summary.UniqueProcesses, 0)
        }

        if ($topProcesses.Count -gt 0) {
            $insights.TopProcess = $topProcesses[0]
            if ($summary.TotalRecords -gt 0) {
                $insights.ProcessPercentage = [math]::Round(($insights.TopProcess.Count / $summary.TotalRecords) * 100, 1)
            }
        }

        if ($topOperations.Count -gt 0) {
            $insights.TopOperation = $topOperations[0]
        }

        return $insights
    }

    [void] AddCustomSchema([string]$schemaName, [hashtable]$schema) {
        $this.Schemas[$schemaName] = $schema
    }

    [bool] ValidateData([hashtable]$data, [string]$schemaName) {
        try {
            $this.BindObject($data, $schemaName)
            return $true
        }
        catch {
            return $false
        }
    }
}

# Helper functions for data preparation
function ConvertTo-DataBindingFormat {
    <#
    .SYNOPSIS
        Converts raw Procmon data to the format expected by the data binder
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DataObject,

        [Parameter(Mandatory = $true)]
        [hashtable]$SessionInfo,

        [Parameter(Mandatory = $false)]
        [int]$MaxSampleSize = 5000,

        [Parameter(Mandatory = $false)]
        [int]$TopItemsCount = 15
    )

    # Extract and process top processes
    $topProcesses = @()
    if ($DataObject.Summary.ProcessTypes) {
        $topProcesses = $DataObject.Summary.ProcessTypes.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First $TopItemsCount |
            ForEach-Object {
                @{
                    Name = $_.Key
                    Count = $_.Value
                }
            }
    }

    # Extract and process top operations
    $topOperations = @()
    if ($DataObject.Summary.Operations) {
        $topOperations = $DataObject.Summary.Operations.GetEnumerator() |
            Sort-Object Value -Descending |
            Select-Object -First $TopItemsCount |
            ForEach-Object {
                @{
                    Name = $_.Key
                    Count = $_.Value
                }
            }
    }

    # Sample events for display
    $sampleEvents = @()
    if ($DataObject.Events) {
        $sampleSize = [Math]::Min($MaxSampleSize, $DataObject.Events.Count)
        $sampleEvents = $DataObject.Events | Select-Object -First $sampleSize |
            ForEach-Object {
                @{
                    Time = $_.TimeOfDay
                    ProcessName = $_.ProcessName
                    Operation = $_.Operation
                    Path = $_.Path
                    Result = $_.Result
                }
            }
    }

    # Prepare chart data
    $processChartData = @{
        Labels = ($topProcesses | ForEach-Object { "'$($_.Name -replace "'", "\'")'" }) -join ','
        Data = ($topProcesses | ForEach-Object { $_.Count }) -join ','
    }

    $operationChartData = @{
        Labels = ($topOperations | ForEach-Object { "'$($_.Name -replace "'", "\'")'" }) -join ','
        Data = ($topOperations | ForEach-Object { $_.Count }) -join ','
    }

    return @{
        SessionInfo = $SessionInfo
        Summary = $DataObject.Summary
        TopProcesses = $topProcesses
        TopOperations = $topOperations
        SampleEvents = $sampleEvents
        ProcessChartData = $processChartData
        OperationChartData = $operationChartData
    }
}

# Export functions
Export-ModuleMember -Function ConvertTo-DataBindingFormat

