@{
    # Profile-Specific Configuration for Procmon Analysis Suite
    # These profiles override default settings for specific use cases

    # Default Profile - Balanced settings for general use
    Default = @{
        Processing = @{
            BatchSize = 100000
            MaxFileSize = 2000
            ValidationLevel = "Standard"
        }
        Memory = @{
            ThresholdMB = 500
            ForceGCThresholdMB = 2000
        }
        Logging = @{
            Level = "INFO"
            EnableFileOutput = $true
            EnableConsoleOutput = $true
        }
        Features = @{
            EnableBackups = $false
            EnableDiagnosticMode = $false
            EnableProgressReporting = $true
        }
    }

    # High Performance Profile - Optimized for speed and throughput
    HighPerformance = @{
        Processing = @{
            BatchSize = 500000
            MaxFileSize = 5000
            ValidationLevel = "Basic"
            ChunkProcessingSize = 50000
        }
        Memory = @{
            ThresholdMB = 1000
            ForceGCThresholdMB = 4000
            MaxCollectionSize = 500000
        }
        Performance = @{
            EnableRegexCaching = $true
            EnableFormatCaching = $true
            MaxCacheSize = 5000
            EnableBatchOptimizations = $true
            MaxDegreeOfParallelism = 8
        }
        Logging = @{
            Level = "WARN"
            EnableFileOutput = $true
            EnableConsoleOutput = $false
            EnablePerformanceLogging = $true
        }
        Features = @{
            EnableBackups = $false
            EnableDiagnosticMode = $false
            EnableProgressReporting = $false
        }
    }

    # Low Memory Profile - Optimized for memory-constrained environments
    LowMemory = @{
        Processing = @{
            BatchSize = 10000
            MaxFileSize = 100
            ValidationLevel = "Basic"
            ChunkProcessingSize = 1000
        }
        Memory = @{
            ThresholdMB = 100
            ForceGCThresholdMB = 500
            MaxCollectionSize = 10000
            OverflowBatchSize = 1000
        }
        FileProcessing = @{
            DefaultBufferSize = 65536  # 64KB
            MaxBufferSize = 262144     # 256KB
        }
        Performance = @{
            EnableRegexCaching = $false
            EnableFormatCaching = $true
            MaxCacheSize = 100
            EnableBatchOptimizations = $false
            MaxDegreeOfParallelism = 1
        }
        Logging = @{
            Level = "ERROR"
            EnableFileOutput = $false
            EnableConsoleOutput = $true
        }
        Features = @{
            EnableBackups = $false
            EnableDiagnosticMode = $false
            EnableProgressReporting = $true
        }
    }

    # Enterprise Profile - Full features with comprehensive logging and backup
    Enterprise = @{
        Processing = @{
            BatchSize = 250000
            MaxFileSize = 10000
            ValidationLevel = "Comprehensive"
        }
        Memory = @{
            ThresholdMB = 1000
            ForceGCThresholdMB = 3000
            MaxCollectionSize = 200000
        }
        Logging = @{
            Level = "DEBUG"
            EnableFileOutput = $true
            EnableConsoleOutput = $true
            EnableStructuredLogging = $true
            IncludeStackTrace = $true
            EnablePerformanceLogging = $true
            LogRetentionDays = 90
        }
        Backup = @{
            EnableByDefault = $true
            MaxBackupsPerSession = 20
            BackupRetentionDays = 30
            CompressBackups = $true
            AutoCleanup = $true
        }
        Security = @{
            EnablePathValidation = $true
            EnableContentSanitization = $true
            TrustedDirectoriesOnly = $true
        }
        ErrorHandling = @{
            MaxRetryAttempts = 5
            RetryDelayMs = 2000
            EnableGracefulDegradation = $true
            DetailedErrorLogging = $true
        }
        Features = @{
            EnableBackups = $true
            EnableDiagnosticMode = $true
            EnableProgressReporting = $true
            EnableInteractiveReports = $true
            EnableOptimizedCSVGeneration = $true
        }
    }

    # Development Profile - Enhanced debugging and testing features
    Development = @{
        Processing = @{
            BatchSize = 50000
            MaxFileSize = 500
            ValidationLevel = "Comprehensive"
        }
        Memory = @{
            ThresholdMB = 200
            ForceGCThresholdMB = 1000
        }
        Logging = @{
            Level = "TRACE"
            EnableFileOutput = $true
            EnableConsoleOutput = $true
            EnableStructuredLogging = $true
            IncludeStackTrace = $true
            EnablePerformanceLogging = $true
        }
        ErrorHandling = @{
            MaxRetryAttempts = 1
            RetryDelayMs = 500
            EnableGracefulDegradation = $false
            ContinueOnNonCriticalErrors = $false
            DetailedErrorLogging = $true
        }
        Features = @{
            EnableBackups = $true
            EnableDiagnosticMode = $true
            EnableProgressReporting = $true
            EnableInteractiveReports = $true
        }
        Validation = @{
            FileHeaderValidation = $true
            ContentIntegrityCheck = $true
            MaxRowEstimateForMemoryCheck = 10000
        }
    }

    # Testing Profile - Optimized for automated testing scenarios
    Testing = @{
        Processing = @{
            BatchSize = 1000
            MaxFileSize = 50
            ValidationLevel = "Standard"
        }
        Memory = @{
            ThresholdMB = 50
            ForceGCThresholdMB = 200
        }
        Logging = @{
            Level = "ERROR"
            EnableFileOutput = $false
            EnableConsoleOutput = $false
        }
        Features = @{
            EnableBackups = $false
            EnableDiagnosticMode = $false
            EnableProgressReporting = $false
        }
        ErrorHandling = @{
            MaxRetryAttempts = 0
            EnableGracefulDegradation = $false
            ContinueOnNonCriticalErrors = $false
        }
    }

    # Production Profile - Stable, reliable settings for production use
    Production = @{
        Processing = @{
            BatchSize = 200000
            MaxFileSize = 3000
            ValidationLevel = "Standard"
        }
        Memory = @{
            ThresholdMB = 800
            ForceGCThresholdMB = 2500
        }
        Logging = @{
            Level = "WARN"
            EnableFileOutput = $true
            EnableConsoleOutput = $true
            LogRetentionDays = 60
        }
        Backup = @{
            EnableByDefault = $true
            BackupRetentionDays = 14
            CompressBackups = $true
            AutoCleanup = $true
        }
        ErrorHandling = @{
            MaxRetryAttempts = 3
            EnableGracefulDegradation = $true
            ContinueOnNonCriticalErrors = $true
        }
        Features = @{
            EnableBackups = $true
            EnableProgressReporting = $true
            EnableInteractiveReports = $false
            EnableOptimizedCSVGeneration = $true
        }
        Security = @{
            EnablePathValidation = $true
            EnableContentSanitization = $true
            TrustedDirectoriesOnly = $true
        }
    }
}
