@{
    # Pattern Definitions for Procmon Analysis Suite
    # Compiled regex patterns for event classification

    # Network-related patterns
    Network = @{
        Protocols = @(
            '(?i)(TCP|UDP|HTTP|HTTPS|FTP|FTPS|SSH|TELNET|SMTP|POP3|IMAP)',
            '(?i)(DNS|DHCP|NTP|SNMP|LDAP|LDAPS)',
            '(?i)(SMB|CIFS|NFS|RDP|VNC)',
            '(?i)(Winsock|netsh|ping|tracert|nslookup)'
        )
        NetworkOperations = @(
            '(?i)(Connect|Disconnect|Bind|Listen|Accept|Send|Receive)',
            '(?i)(Socket|Port|IP|Address|\b(?:\d{1,3}\.){3}\d{1,3}\b)',
            '(?i)(network.*timeout|packet.*drop|connection.*failed|connection.*reset)',
            '(?i)(bandwidth|throughput|latency|packet.*loss)'
        )
        NetworkErrors = @(
            '(?i)(network.*error|connection.*error|socket.*error)',
            '(?i)(timeout.*network|network.*timeout|connection.*timeout)',
            '(?i)(unreachable|host.*down|network.*down)'
        )
    }

    # Input/Output patterns
    IO = @{
        FileOperations = @(
            '(?i)(CreateFile|OpenFile|ReadFile|WriteFile|DeleteFile)',
            '(?i)(CloseFile|FlushFileBuffers|SetFilePointer|GetFileInformation)',
            '(?i)(QueryInformation|SetInformation|QueryDirectory|QueryAttributesFile)'
        )
        DirectoryOperations = @(
            '(?i)(CreateDirectory|RemoveDirectory|QueryDirectory)',
            '(?i)(FindFirstFile|FindNextFile|EnumerateDirectory)',
            '(?i)(Directory|Folder|Path)'
        )
        VolumeOperations = @(
            '(?i)(QueryVolumeInformation|SetVolumeInformation)',
            '(?i)(Volume|Disk|Drive|Mount|Unmount)',
            '(?i)(Format|Defrag|CheckDisk|ScanDisk)'
        )
        IOErrors = @(
            '(?i)(invalid.*I/O|commit.*failure|I/O.*timeout|disk.*timeout)',
            '(?i)(IOCTL|DeviceIoControl|IRP|MDL)',
            '(?i)(buffer.*overflow|access.*denied|sharing.*violation)'
        )
        FileSystem = @(
            '(?i)(NTFS|FAT32|FAT16|ReFS|exFAT)',
            '(?i)(cluster|sector|allocation|MFT|journal)',
            '(?i)(compression|encryption|sparse|reparse)'
        )
    }

    # Security-related patterns
    Security = @{
        Registry = @(
            '(?i)(Registry|HKEY|HKLM|HKCU|HKCR|HKU|HKCC)',
            '(?i)(RegOpen|RegQuery|RegSet|RegDelete|RegCreate)',
            '(?i)(RegQueryValue|RegSetValue|RegDeleteValue|RegEnumKey)'
        )
        Authentication = @(
            '(?i)(Access|Permission|Token|Auth|Login|Logon)',
            '(?i)(Certificate|Credential|Password|PIN|Biometric)',
            '(?i)(Kerberos|NTLM|LDAP|Active.*Directory|AD)'
        )
        Encryption = @(
            '(?i)(SSL|TLS|Encrypt|Decrypt|Certificate|CryptoAPI)',
            '(?i)(Hash|SHA|MD5|AES|RSA|PKI|X509)',
            '(?i)(BitLocker|EFS|Cipher|CNG)'
        )
        SecurityErrors = @(
            '(?i)(ACCESS_DENIED|PRIVILEGE|Audit|Security.*Policy)',
            '(?i)(Rights|Administrator|Elevated|UAC)',
            '(?i)(Firewall|AntiVirus|Malware|Threat)'
        )
    }

    # SCSI and storage-related patterns
    SCSI = @{
        SCSIOperations = @(
            '(?i)(SCSI|ATA|SATA|IDE|NVMe|SAS)',
            '(?i)(Read|Write|Verify|Format|Inquiry)',
            '(?i)(PhysicalDrive|\\Device\\Harddisk|\\Device\\CdRom)'
        )
        StorageErrors = @(
            '(?i)(SCSI.*retry|SCSI.*timeout|SCSI.*error)',
            '(?i)(disk.*error|DR0|disk.*warning|bad.*sector)',
            '(?i)(Event.*153|SCSI.*retries|commit.*failures)'
        )
        StorageHealth = @(
            '(?i)(SMART|temperature|reallocated|pending.*sector)',
            '(?i)(disk.*health|drive.*health|storage.*health)',
            '(?i)(wear.*level|endurance|lifespan)'
        )
    }

    # Hyper-V and virtualization patterns
    HyperV = @{
        HyperVCore = @(
            '(?i)(Hyper-V|VHDX|VHD|Virtual.*Machine|VM)',
            '(?i)(vmwp\.exe|vmms\.exe|vmcompute\.exe)',
            '(?i)(Virtual.*disk|Virtual.*switch|Virtual.*processor)'
        )
        Containers = @(
            '(?i)(Container|Docker|Kubernetes|WSL)',
            '(?i)(runc|containerd|dockerd|wsl\.exe)',
            '(?i)(namespace|cgroup|overlay)'
        )
        VirtualizationFeatures = @(
            '(?i)(snapshot|checkpoint|live.*migration)',
            '(?i)(dynamic.*memory|memory.*ballooning)',
            '(?i)(SR-IOV|VMQ|NUMA)'
        )
    }

    # Error and exception patterns
    Error = @{
        CommonErrors = @(
            '(?i)(ERROR|FAIL|TIMEOUT|DENIED|INVALID)',
            '(?i)(EXCEPTION|CRASH|ABORT|TERMINATE)',
            '(?i)(ACCESS_DENIED|SHARING_VIOLATION|FILE_NOT_FOUND|PATH_NOT_FOUND)'
        )
        MemoryErrors = @(
            '(?i)(BUFFER_OVERFLOW|STACK_OVERFLOW|OUT_OF_MEMORY)',
            '(?i)(INSUFFICIENT_RESOURCES|MEMORY_LEAK|PAGE_FAULT)',
            '(?i)(heap|stack|virtual.*memory|commit.*charge)'
        )
        SystemErrors = @(
            '(?i)(DEVICE_NOT_READY|DEVICE_BUSY|DEVICE_ERROR)',
            '(?i)(SYSTEM_ERROR|KERNEL_ERROR|DRIVER_ERROR)',
            '(?i)(BLUE_SCREEN|BSOD|CRITICAL_ERROR)'
        )
        ApplicationErrors = @(
            '(?i)(application.*error|program.*error|software.*error)',
            '(?i)(runtime.*error|execution.*error|logic.*error)',
            '(?i)(initialization.*error|configuration.*error)'
        )
    }

    # Performance-related patterns
    Performance = @{
        CPUPatterns = @(
            '(?i)(CPU|Processor|Core|Thread|Context.*Switch)',
            '(?i)(Idle|Busy|Load|Utilization|Throttling)',
            '(?i)(Scheduling|Priority|Affinity)'
        )
        MemoryPatterns = @(
            '(?i)(Memory|RAM|Heap|Stack|Virtual.*Memory)',
            '(?i)(Allocation|Deallocation|Paging|Swapping)',
            '(?i)(Working.*Set|Commit.*Charge|Page.*File)'
        )
        DiskPatterns = @(
            '(?i)(Disk.*Queue|IO.*Queue|Disk.*Utilization)',
            '(?i)(Read.*Rate|Write.*Rate|Transfer.*Rate)',
            '(?i)(Seek.*Time|Response.*Time|Throughput)'
        )
        NetworkPatterns = @(
            '(?i)(Bandwidth|Throughput|Latency|RTT)',
            '(?i)(Packet.*Rate|Frame.*Rate|Collision)',
            '(?i)(Queue.*Length|Buffer.*Size|Window.*Size)'
        )
    }

    # Process and thread patterns
    Process = @{
        ProcessOperations = @(
            '(?i)(CreateProcess|TerminateProcess|OpenProcess)',
            '(?i)(Process.*Creation|Process.*Termination)',
            '(?i)(Parent.*Process|Child.*Process|Process.*Tree)'
        )
        ThreadOperations = @(
            '(?i)(CreateThread|TerminateThread|SuspendThread|ResumeThread)',
            '(?i)(Thread.*Creation|Thread.*Termination)',
            '(?i)(Thread.*Pool|Worker.*Thread|UI.*Thread)'
        )
        ProcessCommunication = @(
            '(?i)(IPC|Inter.*Process|Named.*Pipe|Anonymous.*Pipe)',
            '(?i)(Shared.*Memory|Memory.*Mapped|Mutex|Semaphore)',
            '(?i)(Event.*Object|Critical.*Section|Synchronization)'
        )
    }

    # Service and system patterns
    System = @{
        ServiceOperations = @(
            '(?i)(Service|SCM|Service.*Control.*Manager)',
            '(?i)(Start.*Service|Stop.*Service|Install.*Service)',
            '(?i)(Service.*Status|Service.*Configuration)'
        )
        DriverOperations = @(
            '(?i)(Driver|\.sys|Kernel.*Mode|User.*Mode)',
            '(?i)(Load.*Driver|Unload.*Driver|Driver.*Verifier)',
            '(?i)(IOCTL|IRP|DPC|ISR)'
        )
        SystemCalls = @(
            '(?i)(NtCreateFile|NtReadFile|NtWriteFile|NtClose)',
            '(?i)(NtQueryInformation|NtSetInformation)',
            '(?i)(ZwCreateFile|ZwReadFile|ZwWriteFile)'
        )
    }

    # Pattern matching configuration
    Configuration = @{
        # Regex options for compiled patterns
        RegexOptions = @{
            Compiled = $true
            IgnoreCase = $true
            Multiline = $false
            Singleline = $false
            ExplicitCapture = $false
        }

        # Priority order for pattern matching (higher number = higher priority)
        CategoryPriority = @{
            Error = 100
            Security = 90
            Performance = 80
            SCSI = 70
            HyperV = 60
            Network = 50
            IO = 40
            Process = 30
            System = 20
        }

        # Maximum patterns to match per record (0 = unlimited)
        MaxMatchesPerRecord = 1

        # Enable pattern statistics collection
        EnablePatternStatistics = $true

        # Cache compiled patterns for performance
        EnablePatternCaching = $true
        MaxCacheSize = 1000

        # Pattern validation settings
        ValidatePatterns = $true
        TestPatternsOnStartup = $false
    }
}
