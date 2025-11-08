# Professional Report Generator - Refactored

## Overview

This refactored version of the Professional Report Generator implements a modular architecture to address the issues with the original monolithic 2000+ line script. The refactoring focuses on:

- **Modularity**: Separated concerns into distinct modules
- **Maintainability**: Easier to understand, test, and modify
- **Performance**: Better error handling and resource management
- **Security**: Enhanced input validation and sanitization
- **Configuration**: Flexible configuration management
- **Logging**: Comprehensive logging and debugging capabilities

## Architecture

### Core Modules

1. **ReportConfiguration.psm1** - Configuration management
   - Supports multiple formats (JSON, PSD1, XML)
   - Validation and default values
   - Environment-specific configurations

2. **ReportLogger.psm1** - Logging and performance monitoring
   - Multiple log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
   - Performance timing and profiling
   - File and console output
   - Structured logging with context

3. **ReportValidation.psm1** - Input validation and security
   - Comprehensive data validation
   - Security pattern detection
   - XSS prevention with HTML encoding
   - Path traversal protection

4. **Generate-Professional-Report-Refactored.ps1** - Main orchestrator
   - Clean, object-oriented design
   - Modular HTML generation
   - Error handling and recovery
   - Performance optimization

### Key Improvements

#### Before (Original)
- Single 2000+ line file
- Embedded HTML/CSS/JS content
- Limited error handling
- Hard-coded configuration
- No logging infrastructure
- Performance issues with large datasets

#### After (Refactored)
- Modular architecture with 4 focused modules
- Externalized resources (ready for further externalization)
- Comprehensive error handling and validation
- Flexible configuration system
- Structured logging with performance monitoring
- Better performance with StringBuilder and caching

## Usage

### Basic Usage

```powershell
# Import the refactored module
Import-Module ".\Generate-Professional-Report-Refactored.ps1"

# Prepare your data
$dataObject = @{
    Events = $processedEvents
    TotalRecords = 15000
    Summary = @{
        ProcessTypes = @{ 'chrome.exe' = 5000; 'explorer.exe' = 3000 }
        Operations = @{ 'RegOpenKey' = 8000; 'CreateFile' = 7000 }
    }
}

$sessionInfo = @{
    SessionId = 'PROC-2025-001'
    Version = '1.0'
    FilesProcessed = 1
    InputDirectory = 'C:\ProcmonData'
    StartTime = [DateTime]::UtcNow
}

# Generate report
$result = New-ProfessionalReport -DataObject $dataObject -OutputPath ".\report.html" -SessionInfo $sessionInfo

if ($result.Success) {
    Write-Host "Report generated: $($result.ReportPath)"
} else {
    Write-Error "Failed to generate report: $($result.Error)"
}
```

### Advanced Configuration

```powershell
# Custom configuration
$config = @{
    LogLevel = 'DEBUG'
    LogToFile = $true
    LogPath = '.\logs\report.log'
    MaxSampleSize = 10000
    TopItemsCount = 20
    Theme = 'dark'
    EnableAnalytics = $true
}

$result = New-ProfessionalReport -DataObject $dataObject -OutputPath ".\report.html" -SessionInfo $sessionInfo -ReportConfig $config
```

### Configuration File

Create a `report-config.json`:

```json
{
    "LogLevel": "INFO",
    "LogToFile": true,
    "LogPath": "./logs/report.log",
    "MaxSampleSize": 5000,
    "TopItemsCount": 15,
    "Theme": "auto",
    "EnableAnalytics": true,
    "CacheTimeoutMinutes": 30
}
```

Use it:

```powershell
$config = @{ ConfigPath = ".\report-config.json" }
$result = New-ProfessionalReport -DataObject $dataObject -OutputPath ".\report.html" -SessionInfo $sessionInfo -ReportConfig $config
```

## Module Details

### ReportConfiguration

**Functions:**
- `New-ReportConfiguration([string]$ConfigPath)` - Create configuration instance
- `Get-DefaultReportConfig()` - Get default configuration

**Features:**
- Multi-format support (JSON, PSD1, XML)
- Configuration validation
- Environment variable support
- Hierarchical configuration merging

### ReportLogger

**Functions:**
- `New-ReportLogger([hashtable]$Config)` - Create logger instance
- `Get-ReportLogger()` - Get global logger
- `Write-ReportLog([LogLevel]$Level, [string]$Message, ...)` - Write log entry
- `Start-PerformanceTimer([string]$OperationName)` - Start timing
- `Stop-PerformanceTimer([string]$OperationName)` - Stop timing and log

**Features:**
- Colored console output
- File logging with rotation
- Performance profiling
- Structured logging with context
- Memory-efficient log storage

### ReportValidation

**Functions:**
- `New-ReportValidator()` - Create validator instance
- `Test-DataObject([hashtable]$DataObject)` - Validate data object
- `Test-SessionInfo([hashtable]$SessionInfo)` - Validate session info
- `Test-ReportInputs(...)` - Validate all inputs
- `ConvertTo-SafeHTML([string]$Text)` - HTML encode for XSS prevention

**Security Features:**
- Input sanitization
- Path traversal protection
- SQL injection prevention (data validation)
- XSS attack prevention
- Malicious pattern detection

## Performance Improvements

1. **StringBuilder Usage**: HTML generation uses StringBuilder for better memory efficiency
2. **Caching**: Configuration and template caching
3. **Sampling**: Large datasets are sampled for report generation
4. **Lazy Loading**: Modules loaded only when needed
5. **Performance Monitoring**: Built-in timing and profiling

## Security Enhancements

1. **Input Validation**: All inputs validated before processing
2. **HTML Sanitization**: User content HTML-encoded
3. **Path Security**: File paths checked for traversal attacks
4. **Content Security**: Malicious patterns detected and blocked
5. **Error Handling**: Secure error messages (no sensitive data leakage)

## Testing

### Unit Tests Structure

```
Tests/
├── ReportConfiguration.Tests.ps1
├── ReportLogger.Tests.ps1
├── ReportValidation.Tests.ps1
└── ReportGenerator.Tests.ps1
```

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path ".\Tests"

# Run specific module tests
Invoke-Pester -Path ".\Tests\ReportValidation.Tests.ps1"
```

## Migration Guide

### From Original Script

1. **Replace import**: Change from dot-sourcing the large file to importing the refactored module
2. **Update function calls**: `New-ProfessionalReport` has the same interface
3. **Configuration**: Move hard-coded values to configuration files
4. **Error handling**: Leverage improved error reporting
5. **Logging**: Enable logging for better debugging

### Breaking Changes

- Configuration parameters are now case-insensitive
- Some internal function names changed (not exported)
- Enhanced validation may reject previously accepted inputs
- Logging is now enabled by default

## Future Enhancements

1. **External Templates**: Move HTML/CSS/JS to external template files
2. **Database Integration**: Support for storing reports in databases
3. **API Endpoints**: REST API for report generation
4. **Plugin Architecture**: Extensible analytics engines
5. **Cloud Storage**: Support for cloud-based report storage
6. **Real-time Updates**: WebSocket support for live reports

## Contributing

1. Follow PowerShell best practices
2. Add tests for new functionality
3. Update documentation
4. Use semantic versioning
5. Maintain backward compatibility

## License

[Specify your license here]

## Support

For issues and questions:
- Check the logs in `./logs/` directory
- Review configuration in `./config/`
- Enable DEBUG logging for detailed information

