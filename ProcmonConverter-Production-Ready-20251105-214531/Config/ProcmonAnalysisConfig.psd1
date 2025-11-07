@{
    # ProcMon Analysis Configuration
    Version = "9.0-Refactored-Modular"

    # Default Processing Settings
    Processing = @{
        DefaultBatchSize = 100000
        MaxFileSize = 2000
        BufferMinutes = 10
        MaxThreads = 4
        MinMemoryThresholdMB = 500
        MaxConcurrentFiles = 4
        ProgressUpdateInterval = 2000
        BackupInterval = 5
    }

    # Analysis Patterns
    Patterns = @{
        Network = @(
            '(?i)(TCP|UDP|Connect|Network|Socket|HTTP|HTTPS|FTP|DNS|Port|IP|\b(?:\d{1,3}\.){3}\d{1,3}\b)'
            '(?i)(SMB|iSCSI|network.*timeout|packet.*drop|connection.*failed)'
            '(?i)(Winsock|netsh|ping|telnet|ssh|RDP)'
        )
        IO = @(
            '(?i)(CreateFile|ReadFile|WriteFile|QueryInformation|Directory|File|Disk|Volume)'
            '(?i)(invalid.*I/O|commit.*failure|I/O.*timeout|disk.*timeout|IOCTL)'
            '(?i)(NTFS|FAT32|ReFS|mount|unmount|format)'
        )
        Security = @(
            '(?i)(Registry|HKEY|RegOpen|RegQuery|RegSet|Access|Permission|Token|Auth)'
            '(?i)(ACCESS_DENIED|PRIVILEGE|Audit|Security|Policy|Rights)'
            '(?i)(Certificate|Credential|Kerberos|NTLM|SSL|TLS)'
        )
        SCSI = @(
            '(?i)(SCSI.*retry|SCSI.*timeout|SCSI.*error|SCSI)'
            '(?i)(disk.*error|DR0|PhysicalDrive|\\Device\\Harddisk|disk.*warning)'
            '(?i)(Event.*153|SCSI.*retries|commit.*failures|disk.*timeouts)'
        )
        HyperV = @(
            '(?i)(Hyper-V|VHDX|VHD|Virtual.*Machine|VM.*Worker)'
            '(?i)(vmwp\.exe|vmms\.exe|Virtual.*disk|vmcompute)'
            '(?i)(Hyper-V.*Host|Container|Docker|WSL)'
        )
        Error = @(
            '(?i)(ERROR|FAIL|TIMEOUT|DENIED|INVALID|ACCESS_DENIED)'
            '(?i)(BUFFER_OVERFLOW|SHARING_VIOLATION|FILE_NOT_FOUND|PATH_NOT_FOUND)'
            '(?i)(INSUFFICIENT_RESOURCES|OUT_OF_MEMORY|DEVICE_NOT_READY)'
        )
    }

    # UI Styling - Gates Foundation Colors
    Colors = @{
        Primary = '#003f5c'
        Secondary = '#2c5a8e'
        Accent = '#f4d03f'
        Success = '#28a745'
        Warning = '#ffc107'
        Error = '#dc3545'
        Info = '#17a2b8'
        Light = '#f8f9fa'
        Dark = '#343a40'
    }

    # Default Directories
    Directories = @{
        Input = "Data\Converted"
        Output = "Reports"
        Backup = "Backups"
        Temp = "Temp"
        Logs = "Logs"
    }

    # Profile Configurations
    Profiles = @{
        Default = @{
            BatchSize = 100000
            ValidationLevel = 'Standard'
            EnableParallel = $false
            EnableMemoryOptimization = $false
        }
        HighPerformance = @{
            BatchSize = 500000
            ValidationLevel = 'Basic'
            EnableParallel = $true
            EnableMemoryOptimization = $false
        }
        LowMemory = @{
            BatchSize = 10000
            ValidationLevel = 'Basic'
            EnableParallel = $false
            EnableMemoryOptimization = $true
            MaxFileSize = 100
        }
        Enterprise = @{
            BatchSize = 100000
            ValidationLevel = 'Comprehensive'
            EnableParallel = $true
            EnableBackups = $true
            DiagnosticMode = $true
        }
    }
}
