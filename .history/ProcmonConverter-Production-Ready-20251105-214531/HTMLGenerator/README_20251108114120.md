# Modular HTML Generation System

A powerful, modular HTML report generation system for creating professional, interactive reports using templates and components.

## Overview

The Modular HTML Generation System provides a flexible, maintainable way to generate complex HTML reports. It uses a component-based architecture with template inheritance, data binding, and extensive customization options.

## Architecture

```
HTMLGenerator/
├── Core/
│   ├── TemplateEngine.psm1      # Template loading, caching, and rendering
│   └── DataBinder.psm1          # Data validation and type conversion
├── Components/
│   └── SummaryComponent.psm1    # Executive summary component
├── Templates/
│   ├── ReportTemplate.html      # Main report template
│   ├── TabContent.html          # Tab content templates
│   ├── styles.css               # Custom styling
│   └── scripts.js               # JavaScript functionality
└── HTMLGenerator.psm1           # Main orchestrator module
```

## Key Features

- **Template Engine**: Loads and caches HTML templates with placeholder replacement
- **Data Binding**: Type-safe data binding with validation schemas
- **Component System**: Modular components for different report sections
- **Configuration**: Extensive customization options
- **Error Handling**: Comprehensive error reporting and fallback mechanisms
- **Performance**: Template caching and optimized rendering

## Quick Start

### Basic Usage

```powershell
# Import the module
Import-Module ".\HTMLGenerator\HTMLGenerator.psm1"

# Prepare your data
$data = @{
    Events = $processedEvents
    TotalRecords = 15000
    Summary = @{
        ProcessTypes = @{ 'chrome.exe' = 5000; 'explorer.exe' = 3000 }
        Operations = @{ 'RegOpenKey' = 8000; 'CreateFile' = 7000 }
    }
}

$session = @{
    SessionId = 'PROC-2025-001'
    Version = '1.0'
    FilesProcessed = 1
}

# Generate report
$result = New-HTMLReport -DataObject $data -SessionInfo $session -OutputPath "report.html"
```

### Advanced Configuration

```powershell
$config = @{
    MaxSampleSize = 1000
    TopItemsCount = 10
    EnableCache = $true
    StrictMode = $false
    Theme = 'dark'
    SummaryConfig = @{
        EnableHealthScore = $true
        MaxInsights = 8
        MaxRecommendations = 5
    }
    ChartConfig = @{
        Width = 400
        Height = 300
        ColorScheme = 'professional'
        Animation = $true
    }
}

New-HTMLReport -DataObject $data -SessionInfo $session -OutputPath "custom-report.html" -Config $config
```

## Components

### SummaryComponent

Generates the executive summary section with:
- Health score calculation
- Key insights and recommendations
- Interactive elements

### Template Engine Features

- **Simple Placeholders**: `{{variableName}}`
- **Conditional Blocks**: `{{#if condition}}...{{/if}}`
- **Loops**: `{{#each items}}...{{/each}}`
- **Template Caching**: Automatic caching for performance
- **HTML Encoding**: Automatic XSS protection

### Data Binding

The system includes comprehensive data validation:

```powershell
# Data schemas ensure type safety
$schemas = @{
    'SessionInfo' = @{
        Required = @('SessionId', 'Version', 'FilesProcessed')
        Types = @{
            'SessionId' = 'String'
            'FilesProcessed' = 'Int32'
        }
        Validators = @{
            'FilesProcessed' = { param($value) $value -ge 0 }
        }
    }
}
```

## Testing

Run the test script to verify functionality:

```powershell
# Run comprehensive tests
.\Test-ModularHTMLGenerator.ps1

# Or import and run specific tests
Import-Module ".\Test-ModularHTMLGenerator.ps1"
Test-ModularHTMLGenerator
```

## Migration from Legacy System

To migrate from the old inline HTML generation:

1. **Replace** calls to `New-ProfessionalReport` with `New-HTMLReport`
2. **Update** data structure to match expected format
3. **Configure** templates path if different from default
4. **Test** with sample data before production use

### Before (Legacy)
```powershell
$result = New-ProfessionalReport -DataObject $data -OutputPath "report.html" -SessionInfo $session
```

### After (Modular)
```powershell
$result = New-HTMLReport -DataObject $data -SessionInfo $session -OutputPath "report.html" -TemplatePath ".\Templates"
```

## Customization

### Adding Custom Components

```powershell
class MyCustomComponent {
    [string] Render([hashtable]$data) {
        # Your custom rendering logic
        return "<div>My Custom Content</div>"
    }
}

# Add to generator
$generator = [HTMLGenerator]::new(".\Templates")
$generator.AddComponent("MyCustom", [MyCustomComponent]::new())
```

### Custom Templates

Create new templates in the Templates directory and reference them in components:

```html
<!-- MyCustomTemplate.html -->
<div class="custom-section">
    <h3>{{Title}}</h3>
    <p>{{Description}}</p>
    {{#each Items}}
        <div class="item">{{Name}}: {{Value}}</div>
    {{/each}}
</div>
```

## Performance Considerations

- **Template Caching**: Enabled by default, significantly improves performance for repeated report generation
- **Data Sampling**: Configure `MaxSampleSize` to limit memory usage for large datasets
- **Component Lazy Loading**: Components are loaded only when needed

## Error Handling

The system provides comprehensive error handling:

- **Validation Errors**: Clear messages for invalid data
- **Template Errors**: Fallback rendering for missing templates
- **Component Errors**: Isolated failures don't break entire reports
- **File System Errors**: Graceful handling of I/O issues

## Dependencies

- PowerShell 5.1+
- .NET Framework (for HTML encoding)
- Bootstrap 5 (included via CDN)
- Chart.js (included via CDN)
- DataTables (included via CDN)

## Troubleshooting

### Common Issues

1. **Template Not Found**: Ensure template path is correct and files exist
2. **Data Validation Errors**: Check data structure matches expected schema
3. **Component Loading**: Verify component modules are in correct location

### Debug Mode

Enable verbose output for debugging:

```powershell
$VerbosePreference = "Continue"
New-HTMLReport -DataObject $data -SessionInfo $session -OutputPath "debug-report.html"
```

## Future Enhancements

- Additional component types (Charts, Analytics, ML Insights)
- Template inheritance and composition
- Report themes and branding
- Export to multiple formats (PDF, JSON)
- Real-time report updates

## Contributing

To extend the system:

1. Create new components in `Components/` directory
2. Add templates to `Templates/` directory
3. Update schemas in `DataBinder.psm1`
4. Add tests to `Test-ModularHTMLGenerator.ps1`

## License

This module is part of the ProcmonConverter project.

