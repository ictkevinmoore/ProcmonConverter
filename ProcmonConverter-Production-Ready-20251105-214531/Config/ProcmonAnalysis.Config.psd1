@{
    # Main Configuration for Procmon Analysis Suite
    # Version: 9.0-Refactored-Edition

    # Application Metadata
    Application = @{
        Name = "Ultimate Consolidated Procmon Analysis Suite"
        Version = "9.0-Refactored-Edition"
        Author = "Ultimate Analysis Suite - Refactored"
        RequiredPowerShellVersion = "7.2"
        Description = "Comprehensive Procmon analysis with modular architecture"
    }

    # Default Processing Settings
    Processing = @{
        DefaultBatchSize = 100000
        MaxBatchSize = 1000000
        MinBatchSize = 1000
        DefaultMaxFileSize = 2000  # MB
        MaxMaxFileSize = 10000     # MB
        MinMaxFileSize = 1         # MB
        DefaultValidationLevel = "Standard"
        SupportedValidationLevels = @("Basic", "Standard", "Comprehensive")
        DefaultAnalysisMode = "All"
        SupportedAnalysisModes = @("All", "Network", "IO", "Security", "SCSI", "Performance")
    }

    # Memory Management Settings
    Memory = @{
        DefaultThresholdMB = 500
        DefaultForceGCThresholdMB = 2000
        GCCheckIntervalMs = 5000
        MaxCollectionSize = 100000
        OverflowBatchSize = 10000
    }

    # Directory Structure
    Directories = @{
        DefaultInput = "Data\Converted"
        DefaultOutput = "Enhanced-Analysis-Reports"
        Backup = "Backups"
        Templates = "Templates"
        Logs = "Logs"
        Config = "Config"
        Tests = "Tests"
        TempData = "Temp"
    }

    # Progress and Reporting
    Reporting = @{
        ProgressUpdateIntervalMs = 2000
        EnableProgressByDefault = $true
        DefaultReportFormat = "HTML"
        SupportedReportFormats = @("HTML", "CSV", "JSON", "XML")
        MaxErrorsPerCategory = 1000
        DisplayUpdateInterval = 10
    }

    # File Processing
    FileProcessing = @{
        DefaultBufferSize = 1048576  # 1MB
        MaxBufferSize = 10485760     # 10MB
        MinBufferSize = 65536        # 64KB
        SupportedEncodings = @("UTF8", "ASCII", "Unicode")
        DefaultEncoding = "UTF8"
        ChunkProcessingSize = 10000
        MaxParsingErrors = 1000
    }

    # Security Settings
    Security = @{
        EnablePathValidation = $true
        AllowedFileExtensions = @(".csv", ".txt", ".log")
        BlockedCharacters = @('\x00', '\x01-\x08', '\x0B', '\x0C', '\x0E-\x1F', '\x7F')
        MaxPathLength = 260
        EnableContentSanitization = $true
        TrustedDirectoriesOnly = $true
    }

    # Performance Tuning
    Performance = @{
        EnableRegexCaching = $true
        EnableFormatCaching = $true
        MaxCacheSize = 1000
        EnableBatchOptimizations = $true
        ParallelProcessingThreshold = 100000
        MaxDegreeOfParallelism = 4
    }

    # Logging Configuration
    Logging = @{
        DefaultLevel = "INFO"
        SupportedLevels = @("TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL")
        EnableConsoleOutput = $true
        EnableFileOutput = $true
        MaxLogFileSize = "10MB"
        LogRetentionDays = 30
        LogFilePattern = "ProcmonAnalysis-{SessionId}-{Date}.log"
        EnableStructuredLogging = $true
        IncludeStackTrace = $false
        EnablePerformanceLogging = $true
    }

    # Backup System
    Backup = @{
        EnableByDefault = $false
        MaxBackupsPerSession = 10
        BackupRetentionDays = 7
        CompressBackups = $true
        BackupPhases = @("Validation", "Processing", "Analysis", "Output")
        AutoCleanup = $true
    }

    # Error Handling
    ErrorHandling = @{
        MaxRetryAttempts = 3
        RetryDelayMs = 1000
        EnableGracefulDegradation = $true
        ContinueOnNonCriticalErrors = $true
        ErrorCorrelationEnabled = $true
        DetailedErrorLogging = $true
    }

    # HTML Report Styling
    HtmlStyling = @{
        Colors = @{
            Primary = '#003f5c'
            Secondary = '#2c5a8e'
            Accent = '#f4d03f'
            Success = '#28a745'
            Warning = '#ffc107'
            Error = '#dc3545'
            Background = '#ffffff'
            Text = '#212529'
            CardBackground = '#f8f9fa'
        }
        Fonts = @{
            Primary = "Arial, sans-serif"
            Monospace = "'Courier New', monospace"
            Headings = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
        }
        Layout = @{
            MaxWidth = "1200px"
            CardBorderRadius = "5px"
            GridGap = "15px"
            Padding = "20px"
        }
    }

    # Feature Flags
    Features = @{
        EnableInteractiveReports = $true
        EnableOptimizedCSVGeneration = $true
        EnableAdvancedPatternMatching = $true
        EnableRealTimeProcessing = $false
        EnableCloudIntegration = $false
        EnableMachineLearningAnalysis = $false
        EnableAPIEndpoints = $false
        EnablePluginSystem = $false
    }

    # Validation Rules
    Validation = @{
        RequiredColumns = @("Time of Day", "Process Name", "Operation", "Result")
        OptionalColumns = @("PID", "TID", "Path", "Detail", "Duration")
        MaxFieldLength = 32767
        MinRowsForValidFile = 1
        MaxRowEstimateForMemoryCheck = 1000000
        FileHeaderValidation = $true
        ContentIntegrityCheck = $true
    }
}
