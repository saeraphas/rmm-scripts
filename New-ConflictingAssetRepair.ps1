[CmdletBinding()]
Param()

$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#define paths
$provider = "Nexigen"
$LocalPath = "c:\$($provider)\NCentral"
$appName = "Windows Agent"
$server = "ncentral.nexigen.com"
$siteNumber = "873"
$siteRegistrationKey = "92849917-02ab-ca24-bc48-b322340477c7"

function clearWMI() {
    $class = 'NCentralAssetTag'
    $namespace = 'root\cimv2\NCentralAsset'
    try { $wmiAssetTag = Get-WmiObject -Namespace $namespace -Class $class -ErrorAction Stop | Remove-WmiObject }
    catch { write-host $_ }
    
    If ($null -eq $wmiAssetTag) { write-host "N-central Asset Tag no longer exists in WMI." }
    Else {
        Remove-WmiObject $wmiAssetTag
        write-host "WMI entry cleared."
    }
}
    
function clearReg() {
    $path = 'HKLM:\SOFTWARE\N-able Technologies\NcentralAsset'
    $name = 'NcentralAssetTag'
    try { $regAssetTag = Get-ItemProperty -Path $path -Name $name -ErrorAction Stop }
    catch { write-host $_ } 
    If ($null -eq $regAssetTag) { write-host "N-central Asset Tag no longer exists in the registry." }
    Else {
        Remove-ItemProperty -Path $path -Name $name -Force
        write-host "Registry entry cleared."
    }
}
    
function clearFile() {
    If (Test-Path -LiteralPath "C:\Program Files (x86)\N-able Technologies\NcentralAsset.xml") {
        try { Remove-Item -path "C:\Program Files (x86)\N-able Technologies\NcentralAsset.xml" -ErrorAction Stop }
        catch { write-host $_ }
        write-host "The xml file was removed."
    }
    Else { write-host "The xml file does not exist." }
}
      
function RemoveAssetTag() {
    clearWMI
    clearReg
    clearFile
}
    
RemoveAssetTag


Write-Verbose "Checking for old versions of the application $appName."
#avoid querying Win32_Product by filtering registry uninstall values for this app name
    
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

$sleepSeconds = 180
Write-Verbose "Sleeping for $sleepSeconds seconds."
Write-Warning "Delete the device from NCentral inventory NOW!"
Start-Sleep -Seconds $sleepSeconds

#Install new agent
Write-Verbose "Downloading and installing new agent."
#configure paths
$EXERemotePath = "https://ncentral.nexigen.com/download/2024.6.1.27/winnt/N-central/WindowsAgentSetup.exe"
$EXEFile = "WindowsAgentSetup.exe"
$LocalInstallerPath = "c:\Nexigen\NCentral"
New-Item $LocalInstallerPath -ItemType Directory -ErrorAction SilentlyContinue

#hide download progress to prevent transfer slowdown
$ProgressPreference = 'SilentlyContinue'
#bitmask add TLS 1.2 to the protocols used for this session
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
#download the installer
$webClient = New-Object System.Net.WebClient
$url = $EXERemotePath
$file = "$($LocalInstallerPath)\$EXEFile"

$installerExists = test-path -Path $file
if ($installerExists) {
    Write-Verbose "Found $file."
} else {
    Write-Verbose "Attempting to download $EXERemotePath to $file."
    $webClient.DownloadFile($url, $file)
}

#install the EXE
Write-Verbose "Starting installer."
$ArgumentList = "/s /v`" /qn CUSTOMERID=$siteNumber REGISTRATION_TOKEN=$siteRegistrationKey CUSTOMERSPECIFIC=1 SERVERPROTOCOL=HTTPS SERVERADDRESS=$server SERVERPORT=443`""
Start-Process -FilePath $file -ArgumentList $ArgumentList -verb runas


Write-Verbose "Finished in $($Stopwatch.Elapsed.TotalSeconds) seconds."
$Stopwatch.Stop()