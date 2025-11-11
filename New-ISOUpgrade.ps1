# Configure this section
$provider = "Nexigen"
$activity = "Repair"
#URIPrompt = Read-Host "Enter the download link for the remote file source"
$URI25H2 = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENT_CONSUMER_x64FRE_en-us.iso"
$URI = $URI25H2
#ExpectedHash = "Enter the SHA256 hash of the remote file source"
$ExpectedHash = "D141F6030FED50F75E2B03E1EB2E53646C4B21E5386047CB860AF5223F102A32"

# Don't configure below here

#todo, maybe: 
#dynamically select URI and SHA256 from a table of ISOs in blob storage if there's a match on UBR? 
# $OSBuild = "{0}.{1}.{2}.{3}" -f ('CurrentMajorVersionNumber','CurrentMinorVersionNumber','CurrentBuild','UBR' | ForEach-Object {Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion' -Name $_})


# Check for Fortinet EDR since it breaks everything useful
$FortinetEDRPresent = Get-Service -Name "FortiEDR Collector Service" -ErrorAction SilentlyContinue
if ($FortinetEDRPresent) { Write-Warning "Fortinet EDR service present on this machine. Request SOC set EDR bypass on $($Env:COMPUTERNAME)."}

$filename = [System.IO.Path]::GetFileName($URI)
$destination = "$Env:SystemDrive\$provider\$activity\$filename"
$folderPath = Split-Path $destination

# Create destination directory and subdirectories
$null = New-Item -Path $folderPath -ItemType Directory -Force

# Check if the file already exists
$downloadExists = Test-Path -Path $destination

# Download the file only if it doesn't exist
if (-not $downloadExists) {
    Write-Host "Downloading file..."

    # Suppress progress bar during download
    $originalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    # Download the file
    Invoke-WebRequest -Uri $URI -OutFile $destination

    # Restore progress bar
    $ProgressPreference = $originalProgressPreference

} else {
    Write-Host "File already exists at $destination, skipping download."
}

# Verify SHA-256 hash
$computedHash = (Get-FileHash -Path $destination -Algorithm SHA256).Hash.ToUpper()
if ($computedHash -ne $ExpectedHash.ToUpper()) {
    Write-Error "SHA-256 hash mismatch! Expected: $ExpectedHash, Got: $computedHash"
    exit 1
} else {
    Write-Host "SHA-256 hash verified successfully."
    Mount-DiskImage -ImagePath $destination	
    $mountResult = Mount-DiskImage -ImagePath $destination -PassThru
    $driveLetter = $($mountResult | Get-Volume).DriveLetter
        
    $setup = "$driveLetter" + ":\setup.exe"
    
    $process = $setup
    $argumentList = @(
        "/Auto Upgrade",
        "/DynamicUpdate Disable",
        "/Telemetry Disable",
        "/ShowOOBE None",
        "/Compat IgnoreWarning",
        "/BitLocker AlwaysSuspend",
        "/EULA Accept"
    )
    
Write-Output "`nStarting Windows Upgrade from ISO...`n"
    #Start-Process -FilePath $process -ArgumentList $argumentList -NoNewWindow -Wait

}

