function Start-WindowsPrivacySetup {
    <#
    .SYNOPSIS
        Windows‑hardening script disables telemetry, unnecessary background services,
        and several privacy‑leaking features, but keeps the Microsoft Store and its
        automatic update path functional.

    .NOTES
        • Tested on Windows 11 build 26200.7840 Version 25H2.
        • After running, reboot the computer for all changes to take effect.
        • Create a System Restore point before applying if you want an easy rollback.
    #>

    # Admin check

    if (-not ([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match "S-1-5-32-544")) {
        Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
        exit 1
    }

    
    # Package List
    
    $Packages = @(
        'Streetwriters.Notesnook',
        'sublimeHQ.Sublimetext.4',
        'Microsoft.Visualstudio.2022.community',
        'Proton.ProtonDrive',
        'Proton.ProtonMail',
        'Proton.ProtonVPN',
        'Proton.ProtonPass',
        'Git.Git',
        'Mozilla.firefox',
        #'Valve.Steam',
        'ShareX.ShareX',
        'Docker.DockerDesktop',
        'Microsoft.WSL',
        'Microsoft.PowerShell',
        'Microsoft.VisualStudioCode'
    )

    foreach ($Package in $Packages) {
        Write-Host "Install/Updating: $Package" -ForegroundColor Yellow
        winget install $Package --accept-package-agreements
        Write-Host "Completed: $Package" -Foregroundcolor Green
    }
    Write-Host "Package install finished" -ForegroundColor Green

    
    # Registry Config list
    
    $PathHKLM = @{
        ## Disables Onedrive entirely
        Onedrive = @{
            Keypath = 'HKLM:\Software\Policies\Microsoft\Windows\OneDrive' 
            Name = 'DisableFileSyncNGSC'
            Value = 1
            Type = 'Dword'
        }
        ## Sends basic info to Microsoft to keep Windows secure. Set 1 one for minimum diagnostic data.
        DataCollection = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
            Name = 'AllowTelemetry'
            Value = 0
            Type = 'Dword'
        }
        ## Disables Advertising ID (Single User)
        Advertising1 = @{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            Name = 'Enabled'
            Value = 0
            Type = 'Dword'
        }
        ## Disables Advertising ID (All Users)
        Advertising2 = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'
            Name = 'DisabledByGroupPolicy'
            Value = 1
            Type = 'Dword'
        }
        ## Prevents peer-to-peer update sharing (Does not affect the normal Windows update flow)
        DeliveryOC = @{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'
            Name = 'DODownloadMode'
            Value = 0
            Type = 'Dword'
        }
        ## Turns off talored experience
        CloudContent = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
            Name = 'DisableTailoredExperiencesWithDiagnosticData'
            Value = 1
            Type = 'Dword'
        }
        ## Disables Compattelrunner (Registry entry should get deleted)
        Compatrunner = @{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Telemetry'
            Name = 'Remove'
        }
        ## Stops error reports to Microsoft
        ErrorreportPolicy = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'
            Name = 'Disabled'
            Value = 1
            Type = 'Dword'
        }
        ## Disables Windows Error Reporting
        ErrorreportMicrosoft = @{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'
            Name = 'Disable'
            Value = 1
            Type = 'Dword'
        }
        ## Disables Customer improvement Program 
        CustomerIP = @{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\SQMClient\Windows'
            Name = 'CEIPEnable'
            Value = 0
            Type = 'Dword'
        }
        ## Disables Connected Device telemetry (CDP)
        CDPT = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
            Name = 'EnableCdp'
            Value = 0
            Type = 'Dword'
        }
        ## Disable Feedback Hub telemetry
        Feedback = @{
            Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Feedback'
            Name = 'DisableFeedback'
            Value = 1
            Type = 'Dword'
        }   
        ## Suppress SIUF (Send Optional Diagnostic Data) prompts
        SIUFprompts = @{
            Keypath = 'HKCU:\Software\Microsoft\Siuf\Rules'
            Name = 'NumberOfSIUFInPeriod'
            Value = 0
            Type = 'DWord'
        }
        ## Disables location services -- Uncomment if you want it Disabled --
        #Location = @{
        #    Keypath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'
        #    Name = 'DisableLocation'
        #    Value = 1
        #    Type = 'Dword'
        #}
        ## For passwordless device (Not recommended unless you can do soley biometrics)
        NoPassword =@{
            Keypath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
            Name = 'DevicePasswordlessBuildVersion'
            Value = 0
            Type= 'Dword'
        }
    }

    foreach ($item in $PathHKLM.GetEnumerator()) {
        $config = $item.Value
        $keyPath = $config.Keypath
        $name = $config.Name
        $value = $config.Value
        $type = $config.Type

        # Determine registry hive
        if ($keyPath -match "^HKLM:\\(.*)") {
            $baseHive = [Microsoft.Win32.Registry]::LocalMachine
            $subKeyPath = $matches[1]
        } 
        elseif ($keyPath -match "^HKCU:\\(.*)") {
            $baseHive = [Microsoft.Win32.Registry]::CurrentUser
            $subKeyPath = $matches[1]
        } 
        else {
            Write-Warning "Unrecognized hive in path: $keyPath. Skipping..."
            continue
        }

        # Delete key if value is null or marked for removal
        if ($null -eq $value -or $name -eq 'Remove') {
            try {
                $baseHive.DeleteSubKeyTree($subKeyPath, $false)
                Write-Host "DELETED KEY: $keyPath" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "Failed to delete key: $keyPath. $($_.Exception.Message)"
            }
        } 
        else {       
        # Set registry value
            $regKey = $null
            try {
                $regKey = $baseHive.CreateSubKey($subKeyPath, $true)
                $valueKind = [System.Enum]::Parse([Microsoft.Win32.RegistryValueKind], $type, $true)
                $regKey.SetValue($name, $value, $valueKind)
                Write-Host "SET VALUE: $keyPath\$name = $value ($type)" -ForegroundColor Green
            } 
            catch {
                Write-Warning "Failed to set value for: $keyPath\$name. $($_.Exception.Message)"
            } 
            finally {
                if ($null -ne $regKey) {
                    $regKey.Close()
                    $regKey.Dispose()
                }
            }
        }
    }

    
    # Installs windows capabilities
    
    $ErrorActionPreference = "Continue"

    Get-WindowsCapability -Online | 
        Where-Object -Property Name -like "*media*" |
        Where-Object -Property State -ne "Installed" |
        ForEach-Object {
            try {
                Add-WindowsCapability -Online -Name $_.Name -ErrorAction Stop | Out-Null
                Write-Host "Installed: $($_.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "Already installed or error: $($_.Name)" -ForegroundColor Yellow
            }
        }

    # Enables windows media player
        
    try {
        $feature = Get-WindowsOptionalFeature -FeatureName "WindowsMediaPlayer" -Online -ErrorAction Stop
        
        if ($feature.State -eq "Disabled") {
            Enable-WindowsOptionalFeature -FeatureName "WindowsMediaPlayer" -All -Online -NoRestart -ErrorAction Stop | Out-Null
            Write-Host "WindowsMediaPlayer enabled" -ForegroundColor Green
        }
        else {
            Write-Host "WindowsMediaPlayer already enabled" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "WindowsMediaPlayer already enabled or unavailable" -ForegroundColor Yellow
    }

    # Disables optional featuers
    
    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue

    try {
        Disable-WindowsOptionalFeature -Online -FeatureName HomeGroup -NoRestart -ErrorAction Stop
        Write-Host "Disabled: HomeGroup" -ForegroundColor Green
    }
    catch {
        Write-Host "HomeGroup feature not found or already disabled (not available on this Windows version)" -ForegroundColor Yellow
    }

    # Disables superfluous services
    
    Get-Service -Name 'SysMain' -ErrorAction SilentlyContinue |
        Set-Service -StartupType Disabled -PassThru |
        Stop-Service -Force -ErrorAction SilentlyContinue

    $telemetrySvcs = @('DiagTrack', 'dmwappushservice')
    foreach ($svc in $telemetrySvcs) {
        Get-Service -Name $svc -ErrorAction SilentlyContinue |
            Set-Service -StartupType Disabled -PassThru |
            Stop-Service -Force -ErrorAction SilentlyContinue
    }

    # OPTIONAL: Disable Windows Search indexing (uncomment if you never use search)
    # Get-Service -Name 'WSearch' -ErrorAction SilentlyContinue |
    #     Set-Service -StartupType Disabled -PassThru |
    #     Stop-Service -Force -ErrorAction SilentlyContinue

    $ErrorActionPreference = "Default"
}

Start-WindowsPrivacySetup