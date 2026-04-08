# windows-privacy-setup
Automates Windows Privacy hardening and Installs Dev Applications, Proton Suite, and some extras.

# Windows Privacy Setup Script

## Overview
Start-WindowsPrivacySetup.ps1 is a PowerShell script that automates privacy, security, and system configuration tasks for Windows.

It is designed to quickly set up a clean and controlled environment while keeping essential features, such as the Microsoft Store and its automatic update path, functional.

## Features
* Disables telemetry and unnecessary data collection
* Applies privacy-focused Windows registry settings
* Installs and updates essential software via winget
* Configures system capabilities, including media features
* Disables optional features like SMB1 and HomeGroup
* Stops superfluous or telemetry-related services
* Optional features, like disabling Windows Search indexing, are included but commented out for safety

## Why I Built This

Rebuilding systems manually is time-consuming and inconsistent.
This script ensures every machine starts from a known, controlled baseline with minimal effort.

## Usage

Run PowerShell as Administrator:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Start-WindowsPrivacySetup.ps1
```
## Example Output
```powershell
[INFO] Starting Windows privacy setup...
[INFO] Installing/Updating: Mozilla.Firefox
[SUCCESS] Completed: Mozilla.Firefox
[INFO] Installing/Updating: Git.Git
[SUCCESS] Completed: Git.Git
[SUCCESS] Package installation complete.
[SUCCESS] Set HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry = 0
[SUCCESS] Disabled service: SysMain
[SUCCESS] Setup complete. Reboot recommended.
```

## Notes & Warnings
* Intended for personal or development environments
* Some changes may affect Windows features depending on configuration
* Review the script before running on production machines
* A system restore point is recommended for easy rollback
* After running a reboot is recommended

## Future Improvements

* Modular function structure for easier maintenance
* Logging and output reporting
* Optional configuration flags
* Safer rollback options
