<#
.SYNOPSIS
Downloads and installs Cisco AnyConnect Secure Mobility Client along with its profile and preferences.

.DESCRIPTION
This script downloads the Cisco AnyConnect Secure Mobility Client installer, profile, and preferences from specified remote URLs if they do not already exist locally. 
It then installs the client quietly without restarting the system and copies the profile and preferences to the appropriate directories.

.EXAMPLE
	.\New-CiscoAnyConnectInstallation.ps1 -Verbose

.NOTES
    Author:             Douglas Hammond (douglas@douglashammond.com)
	License: 			This script is distributed under "THE BEER-WARE LICENSE" (Revision 42):
						As long as you retain this notice you can do whatever you want with this stuff.
						If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

.LINK
	https://github.com/saeraphas/

#>
[CmdletBinding()]
Param()

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#define paths
$provider = "Nexigen"
$LocalPath = "c:\$($provider)\Cisco_AnyConnect"

Write-Verbose "Checking for old versions of the application."
#avoid querying Win32_Product by filtering registry uninstall values for this app name
$appName = "AnyConnect"

# Search the registry for the ProductCode
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$Products = foreach ($path in $registryPaths) { Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { ($_.DisplayName -match $appName) -and ($_.UninstallString -match "MsiExec.exe") } | Select-Object -ExpandProperty PSChildName }
foreach ($Product in $Products) { 
    Write-Verbose "Calling uninstall for $Product."
    $LogFile = "$LocalPath\uninstall.log"
    $argumentList = @(
        "/X$product"
        "/norestart"
        "/quiet"
        "/log $LogFile"
    )
    Start-Process msiexec.exe -ArgumentList $argumentList -Wait
}

Write-Verbose "Checking for local files and downloading if necessary."
# define download links and local paths
$LocalProfile = "$LocalPath\Profile - Ohio Masonic Homes.xml"
$LocalInstaller = "$LocalPath\cisco-secure-client-win-5.1.7.80-core-vpn-predeploy-k9.msi"
$LocalSBLInstaller = "$LocalPath\cisco-secure-client-win-5.1.7.80-sbl-predeploy-k9.msi"
$LocalGlobalPreferences = "$LocalPath\preferences_global.xml"
$LocalUserPreferences = "$LocalPath\preferences_global.xml"
$RemoteProfile = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/Profile%20-%20Ohio%20Masonic%20Homes.xml"
$RemoteInstaller = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/cisco-secure-client-win-5.1.7.80-core-vpn-predeploy-k9.msi"
$RemoteSBLInstaller = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/cisco-secure-client-win-5.1.7.80-sbl-predeploy-k9.msi"
$RemoteGlobalPreferences = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/preferences_global.xml"
$RemoteUserPreferences = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/preferences.xml"

# Ensure TLS 1.2 is used for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create local staging directory if it doesn't exist
if (-Not (Test-Path -Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null }

# Hide download progress
Set-Variable ProgressPreference SilentlyContinue

# Download files if they do not exist
if (-Not (Test-Path -Path $LocalProfile)) { Invoke-WebRequest -Uri $RemoteProfile -OutFile $LocalProfile -UseBasicParsing }
if (-Not (Test-Path -Path $LocalInstaller)) { Invoke-WebRequest -Uri $RemoteInstaller -OutFile $LocalInstaller -UseBasicParsing }
if (-Not (Test-Path -Path $LocalSBLInstaller)) { Invoke-WebRequest -Uri $RemoteSBLInstaller -OutFile $LocalSBLInstaller -UseBasicParsing }
if (-Not (Test-Path -Path $LocalGlobalPreferences)) { Invoke-WebRequest -Uri $RemoteGlobalPreferences -OutFile $LocalGlobalPreferences -UseBasicParsing }
if (-Not (Test-Path -Path $LocalUserPreferences)) { Invoke-WebRequest -Uri $RemoteUserPreferences -OutFile $LocalUserPreferences -UseBasicParsing }

Write-Verbose "Copying profiles to local destination paths."
# Copy profile and preferences to the destination directories
$DestinationProfilePath = "C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile"
$DestinationGlobalPreferencesPath = "C:\ProgramData\Cisco\Cisco Secure Client"
$DestinationUserPreferencesPath = "C:\Users\$env:USERNAME\AppData\Local\Cisco\Cisco Secure Client"

if (-Not (Test-Path -Path $DestinationProfilePath)) { New-Item -ItemType Directory -Path $DestinationProfilePath -Force | Out-Null }
if (-Not (Test-Path -Path $DestinationGlobalPreferencesPath)) { New-Item -ItemType Directory -Path $DestinationGlobalPreferencesPath -Force | Out-Null }
if (-Not (Test-Path -Path $DestinationUserPreferencesPath)) { New-Item -ItemType Directory -Path $DestinationUserPreferencesPath -Force | Out-Null }

Copy-Item -Path $LocalProfile -Destination "$DestinationProfilePath\profile.xml" -Force
Copy-Item -Path $LocalGlobalPreferences -Destination "$DestinationGlobalPreferencesPath\preferences_global.xml" -Force
Copy-Item -Path $LocalUserPreferences -Destination "$DestinationUserPreferencesPath\preferences.xml" -Force

Write-Verbose "Installing core components."
# Install the MSI quietly without restarting and create a log file
$LogFile = "$LocalPath\install_core.log"
Start-Process msiexec.exe -ArgumentList "/i $LocalInstaller /quiet /norestart /log $LogFile" -Wait

Write-Verbose "Installing additional components."
# Install the MSI quietly without restarting and create a log file
$LogFile = "$LocalPath\install_sbl.log"
Start-Process msiexec.exe -ArgumentList "/i $LocalSBLInstaller /quiet /norestart /log $LogFile" -Wait
    
#Set-ExecutionPolicy $originalExecutionPolicy
Write-Verbose "Finished in $($Stopwatch.Elapsed.TotalSeconds) seconds."
$Stopwatch.Stop()