# Configure this section
$provider = "Nexigen"
$activity = "Repair"
#URI = Read-Host "Enter the download link for the remote file source"
$URI = "https://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.17050.WINBLUE_REFRESH.140317-1640_X64FRE_SERVER_EVAL_EN-US-IR3_SSS_X64FREE_EN-US_DV9.ISO"
#ExpectedHash = "Enter the SHA256 hash of the remote file source"
$ExpectedHash = "6612B5B1F53E845AACDF96E974BB119A3D9B4DCB5B82E65804AB7E534DC7B4D5"

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
    $volumeInfo = $mountResult | Get-Volume
    $driveLetter = $volumeInfo.DriveLetter
    
    $installWIM = "$driveLetter" + ":\sources\install.wim"
    Write-Host "`nListing available editions in the WIM file:`n$installWIM"

    $process = "dism.exe"
    $argumentList = @(
        "/Get-WimInfo"
        "/WimFile:$installWIM"
    )

    # redirect the output from DISM into a variable we can parse
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $process
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = $argumentList
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    Write-Host "stdout: $stdout"
    Write-Host "stderr: $stderr"
    Write-Host "exit code: " + $p.ExitCode

    # Parse DISM image info in $stdout into objects with Index, Name, Description, Size (bytes)
    $pattern = '(?ms)^Index\s*:\s*(?<Index>\d+)\s*\r?\nName\s*:\s*(?<Name>.+?)\s*\r?\nDescription\s*:\s*(?<Description>.*?)\s*\r?\nSize\s*:\s*(?<Size>[0-9,]+)\s*bytes'

    $index = [regex]::Matches($stdout, $pattern) | ForEach-Object {
        [pscustomobject]@{
            Index       = [int]   $_.Groups['Index'].Value
            Name        = ($_.Groups['Name'].Value -replace '&nbsp;', ' ' ).Trim()
            Description = ($_.Groups['Description'].Value -replace '&nbsp;', ' ' -replace '\s{2,}', ' ' ).Trim()
            Size        = [int64] ( $_.Groups['Size'].Value -replace '[^0-9]', '' )
        }
    }
    $index | Select-Object -Property Index, Name

    # Prompt operator to choose the index of the edition to use as the DISM repair source
    $edition = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption
    Write-Output "Installed Windows Edition is $edition."
    $indexSelection = Read-Host "Enter the index number of the edition that most closely matches the installed Windows Edition"

    # Start DISM using the selected edition index
    $sourceArgument = "$($installWIM):$($indexSelection)"
    $argumentList = @(
        "/Online",
        "/Cleanup-Image",
        "/RestoreHealth",
        "/Source:$sourceArgument",
        "/LimitAccess"
    )
    Start-Process -FilePath $process -ArgumentList $argumentList -NoNewWindow -Wait


}

