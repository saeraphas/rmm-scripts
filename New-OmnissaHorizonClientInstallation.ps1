[CmdletBinding()]

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$provider = "Nexigen"
$LocalPath = "c:\$($provider)\Horizon_Client"
$LogFile = "$LocalPath\install_log.txt"
$LocalInstaller = "$LocalPath\Omnissa-Horizon-Client-2412-8.14.0-12437220870.exe"
$RemoteInstaller = "https://download3.omnissa.com/software/CART25FQ4_WIN_2412/Omnissa-Horizon-Client-2412-8.14.0-12437220870.exe"
$InstallerArguments = @(
    "/silent"
    "/norestart"
    "/log $LogFile"
    "VDM_Server=access.stelizabeth.com"
    )

# Ensure TLS 1.2 is used for downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create local staging directory if it doesn't exist
if (-Not (Test-Path -Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath -Force }

# Hide download progress
Set-Variable ProgressPreference SilentlyContinue

# Download files if they do not exist
if (-Not (Test-Path -Path $LocalInstaller)) { Invoke-WebRequest -Uri $RemoteInstaller -OutFile $LocalInstaller -UseBasicParsing }

# Install the MSI quietly without restarting and create a log file
Start-Process $LocalInstaller -ArgumentList $InstallerArguments -Wait
    
#Set-ExecutionPolicy $originalExecutionPolicy
Write-Verbose "Finished in $($Stopwatch.Elapsed.TotalSeconds) seconds."
$Stopwatch.Stop()