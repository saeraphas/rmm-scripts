[CmdletBinding()]
param()
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#define paths
$provider = "Nexigen"
$scriptLog = "c:\$($provider)\PatchStatusTroubleshooter.log"
$WULog = "c:\$($provider)\WindowsUpdate.log"
$logDirectory = Split-Path $scriptLog
if (-not (Test-Path $logDirectory)) { New-Item -ItemType Directory -Path $logDirectory -Force }
Start-Transcript -Path $scriptLog

$EDRCheck = @'
# Check for Fortinet EDR since it breaks everything useful
$FortinetEDRPresent = Get-Service -Name "FortiEDR Collector Service" -ErrorAction SilentlyContinue
if ($FortinetEDRPresent) { Write-Warning "Fortinet EDR service present on this machine. Engage SOC to set bypass." }
'@

$UpdateProviders = @'
# Enable TLS 1.2 for remote connections
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Check if PowerShellGet is updated (version 2.2.5 or higher)
$updatedPowershellGetInstalled = (@(Get-Module -ListAvailable -Name PowerShellGet | Where-Object { $_.Version -ge [Version]'2.2.5' }).Count -gt 0)

# If it isn't, install NuGet then install the current PowerShellGet
# NOTE: if installing powershellget errors here, this may need to be split off into a separate step
if (-not $updatedPowershellGetInstalled) { 
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    Install-Module -Name PowerShellGet -RequiredVersion 2.2.5 -Force
}

# Re-register the PSGallery module repository
$ErrorActionPreference = "Stop" 
try { Register-PSRepository -Default } catch [System.Exception] { if ("Module Repository 'PSGallery' exists." -ne $($_.Exception.Message)) { Write-Output "Error: $($_.Exception.Message)" } }
$ErrorActionPreference = "Continue"
'@

$UpdateModule = @'
# Install or update PSWindowsUpdate module.
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module PSWindowsUpdate -Force
} else {
    $availablePSWindowsUpdateVersion = Find-Module PSWindowsUpdate | Select-Object -ExpandProperty Version
    $installedPSWindowsUpdateVersion = Get-Module -ListAvailable -Name PSWindowsUpdate | Select-Object -ExpandProperty Version
    if ($installedPSWindowsUpdateVersion -lt $availablePSWindowsUpdateVersion) {
        Find-Module PSWindowsUpdate | Update-Module -Force
    }
}
'@

$ResetWUComponents = @'
# Import the PSWindowsUpdate module; this makes the next commands available
Import-Module PSWindowsUpdate -Force

# Reset Windows Update components. This should complete in 30s or less
# If it doesn't, close your shell and retry the powershell commands, but skip this step
Reset-WUComponents -Verbose
'@

$RetryUpdates = @'
# Import the PSWindowsUpdate module; this makes the next commands available
Import-Module PSWindowsUpdate -Force

# Detect available updates; this will show all updates including those we do not manage
Get-WindowsUpdate

# Manually reinstall filtered set of updates. 
# This may take a long time!
Install-WindowsUpdate -NotCategory "Drivers", "Service Packs", "FeaturePacks" -NotTitle "preview" -AcceptAll
'@

$GetWULogs = @"
Get-WindowsUpdateLog -LogPath $WULog
"@

Write-Output "Checking for FortiEDR"
powershell -executionpolicy bypass -command $EDRCheck
Start-Sleep -Seconds 5
Write-Output "Updating Providers"
powershell -executionpolicy bypass -command $UpdateProviders
Start-Sleep -Seconds 5
Write-Output "Updating Modules"
powershell -executionpolicy bypass -command $UpdateModule
Start-Sleep -Seconds 5
Write-Output "Resetting WU Components"
powershell -executionpolicy bypass -command $ResetWUComponents
Start-Sleep -Seconds 5
Write-Output "Retrying Updates"
powershell -executionpolicy bypass -command $RetryUpdates
Start-Sleep -Seconds 5
Write-Output "Getting WU Logs"
powershell -executionpolicy bypass -command $GetWULogs

Write-Output "Finished in $($Stopwatch.Elapsed.TotalSeconds) seconds."
$Stopwatch.Stop()
Stop-Transcript