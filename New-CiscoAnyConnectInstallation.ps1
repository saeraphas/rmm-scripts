<#
.SYNOPSIS
Downloads and installs Cisco AnyConnect Secure Mobility Client along with its profile and preferences.

.DESCRIPTION
This script downloads the Cisco AnyConnect Secure Mobility Client installer, profile, and preferences from specified remote URLs if they do not already exist locally. 
It then installs the client quietly without restarting the system and copies the profile and preferences to the appropriate directories.

.EXAMPLE
	.\New-FortiClientOperation.ps1 -Mode install -InstallVersion 7.0.11 -Verbose

.NOTES
    Author:             Douglas Hammond (douglas@douglashammond.com)
	License: 			This script is distributed under "THE BEER-WARE LICENSE" (Revision 42):
						As long as you retain this notice you can do whatever you want with this stuff.
						If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

.LINK
	https://github.com/saeraphas/

#>

[CmdletBinding()]

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()


function uninstall() {
    #avoid querying Win32_Product by filtering registry uninstall values for this app name
    $appName = "AnyConnect"

    # Search the registry for the ProductCode
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $Products = foreach ($path in $registryPaths) { Get-ItemProperty $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match $appName } | Select-Object -ExpandProperty PSChildName }
    foreach ($Product in $Products) { Write-Verbose "Calling uninstall for $Product." ; msiexec /uninstall $product /norestart /quiet }
}

uninstall

$provider = "Nexigen"
$LocalPath = "c:\$($provider)\Cisco_AnyConnect"
$LogFile = "$LocalPath\install_log.txt"
$LocalProfile = "$LocalPath\Profile - Ohio Masonic Homes.xml"
$LocalInstaller = "$LocalPath\cisco-secure-client-win-5.1.7.80-core-vpn-predeploy-k9.msi"
$LocalGlobalPreferences = "$LocalPath\preferences_global.xml"
$LocalUserPreferences = "$LocalPath\preferences_global.xml"
$RemoteProfile = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/Profile%20-%20Ohio%20Masonic%20Homes.xml"
$RemoteInstaller = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/cisco-secure-client-win-5.1.7.80-core-vpn-predeploy-k9.msi"
$RemoteGlobalPreferences = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/preferences_global.xml"
$RemoteUserPreferences = "https://nocinstallerstorage.blob.core.windows.net/root/Ohio%20Masonic%20Communities/Cisco%20AnyConnect/preferences.xml"

# Ensure TLS 1.2 is used for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create local staging directory if it doesn't exist
if (-Not (Test-Path -Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath -Force }

# Hide download progress
Set-Variable ProgressPreference SilentlyContinue

# Download files if they do not exist
if (-Not (Test-Path -Path $LocalProfile)) { Invoke-WebRequest -Uri $RemoteProfile -OutFile $LocalProfile -UseBasicParsing }
if (-Not (Test-Path -Path $LocalInstaller)) { Invoke-WebRequest -Uri $RemoteInstaller -OutFile $LocalInstaller -UseBasicParsing }
if (-Not (Test-Path -Path $LocalGlobalPreferences)) { Invoke-WebRequest -Uri $RemoteGlobalPreferences -OutFile $LocalGlobalPreferences -UseBasicParsing }
if (-Not (Test-Path -Path $LocalUserPreferences)) { Invoke-WebRequest -Uri $RemoteUserPreferences -OutFile $LocalUserPreferences -UseBasicParsing }

# Copy profile and preferences to the destination directories
$DestinationProfilePath = "C:\ProgramData\Cisco\Cisco Secure Client\VPN\Profile"
$DestinationGlobalPreferencesPath = "C:\ProgramData\Cisco\Cisco Secure Client"
$DestinationUserPreferencesPath = "C:\Users\$env:USERNAME\AppData\Local\Cisco\Cisco Secure Client"

if (-Not (Test-Path -Path $DestinationProfilePath)) { New-Item -ItemType Directory -Path $DestinationProfilePath -Force }
if (-Not (Test-Path -Path $DestinationGlobalPreferencesPath)) { New-Item -ItemType Directory -Path $DestinationGlobalPreferencesPath -Force }
if (-Not (Test-Path -Path $DestinationUserPreferencesPath)) { New-Item -ItemType Directory -Path $DestinationUserPreferencesPath -Force }

Copy-Item -Path $LocalProfile -Destination "$DestinationProfilePath\profile.xml" -Force
Copy-Item -Path $LocalGlobalPreferences -Destination "$DestinationGlobalPreferencesPath\preferences_global.xml" -Force
Copy-Item -Path $LocalUserPreferences -Destination "$DestinationUserPreferencesPath\preferences.xml" -Force

# Install the MSI quietly without restarting and create a log file
Start-Process msiexec.exe -ArgumentList "/i $LocalInstaller /quiet /norestart /log $LogFile" -Wait
    
#Set-ExecutionPolicy $originalExecutionPolicy
Write-Verbose "Finished in $($Stopwatch.Elapsed.TotalSeconds) seconds."
$Stopwatch.Stop()