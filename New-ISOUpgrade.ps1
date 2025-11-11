# Configure this section
$provider = "Nexigen"
$activity = "Repair"
#URIPrompt = Read-Host "Enter the download link for the remote file source"
$URI25H2 = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENT_CONSUMER_x64FRE_en-us.iso"
$URI = $URI25H2
#ExpectedHash = "Enter the SHA256 hash of the remote file source"
$ExpectedHash = "D141F6030FED50F75E2B03E1EB2E53646C4B21E5386047CB860AF5223F102A32"

# Don't configure below here

# Check for Fortinet EDR since it breaks everything useful
Write-Output "Checking for Fortinet EDR."
$FortinetEDRPresent = Get-Service -Name "FortiEDR Collector Service" -ErrorAction SilentlyContinue
if ($FortinetEDRPresent) { Write-Warning "Fortinet EDR service present on this machine. Request SOC set EDR bypass on $($Env:COMPUTERNAME)." }

$filename = [System.IO.Path]::GetFileName($URI)
$destination = "$Env:SystemDrive\$provider\$activity\$filename"
$folderPath = Split-Path $destination

# Create destination directory and subdirectories
Write-Output "Creating destination directory if it doesn't exist."
$null = New-Item -Path $folderPath -ItemType Directory -Force

# Check if the file already exists
Write-Output "Checking for existing file at $destination."
$downloadExists = Test-Path -Path $destination

# Download the file only if it doesn't exist
if ($downloadExists) {
    Write-Output "File already exists, skipping download."
} else {
    Write-Output "File download starting."

    # Suppress progress bar during download
    $originalProgressPreference = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    # Download the file
    Invoke-WebRequest -Uri $URI -OutFile $destination

    # Restore progress bar
    $ProgressPreference = $originalProgressPreference

    Write-Output "File download completed."
}

# Verify SHA-256 hash
Write-Output "Verifying SHA-256 hash."
$computedHash = (Get-FileHash -Path $destination -Algorithm SHA256).Hash.ToUpper()
if ($computedHash -ne $ExpectedHash.ToUpper()) {
    Write-Error "SHA-256 hash mismatch! Expected: $ExpectedHash, Got: $computedHash"
    Write-Output "Delete the file or update the expected hash and try again."
    exit 1
} else {
    Write-Output "SHA-256 hash verified successfully."

    Write-Output "Mounting ISO."
    $mountedAleady = Get-DiskImage -ImagePath $destination -ErrorAction SilentlyContinue | Where-Object { $_.Attached -eq $true }
    if ($mountedAleady) {
        $driveLetter = $($mountedAleady | Get-Volume).DriveLetter
        Write-Output "ISO is already mounted at $driveletter, skipping mount."
    } else {
        $mountResult = Mount-DiskImage -ImagePath $destination -PassThru
        $driveLetter = $($mountResult | Get-Volume).DriveLetter
        Write-Output "ISO mounted at drive letter: $driveLetter"
    }
    
    $setup = "$driveLetter" + ":\setup.exe"
    Write-Output "Checking for setup.exe."
    $setupExists = Test-Path -Path $setup
    if (-not $setupExists) {
        Write-Error "Setup.exe not found, cannot proceed with upgrade."
        exit 1
    } else {
        Write-Output "Setup.exe found. Starting upgrade process."
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
    
        Write-Output "Starting Windows Upgrade from ISO."
        Write-Verbose "Setup Path: $process"
        #Start-Process -FilePath $process -ArgumentList $argumentList -NoNewWindow -Wait

    }
    
}
