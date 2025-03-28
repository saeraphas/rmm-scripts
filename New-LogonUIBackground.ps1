<#
.SYNOPSIS
Downloads an image and sets it as the Windows logon screen background.

.DESCRIPTION
This script downloads an image from a specified URI and saves it to a local path. 
It ensures the connection uses TLS 1.2 and does not show download progress. 
After downloading, it checks that the file size is less than 256 KB. 
If the file size is acceptable, it sets the image as the Windows logon screen background by updating the registry and copying the image to the required location.

.EXAMPLE
.\new-LogonUIBackground.ps1

.PARAMETER
# (No parameters defined)
#>

[CmdletBinding()]
param ()

# Define the remote image URI and local image path
$remoteImageURI = "https://nocinstallerstorage.blob.core.windows.net/root/Installers/nexigen_logo_on_gray_1920x1080.jpg"
$localImagePath = "C:\nexigen\wallpaper_1920x1080.jpg"

# Check if the local image path already exists
if (Test-Path -Path $localImagePath) {
    Write-Output "The file already exists at $localImagePath."
}
else {
    # Download the image without showing progress
    Invoke-WebRequest -Uri $remoteImageURI -OutFile $localImagePath -UseBasicParsing

    # Ensure TLS 1.2 is used for the connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Download the image without showing progress
    Invoke-WebRequest -Uri $remoteImageURI -OutFile $localImagePath -UseBasicParsing
} 

# Check the file size
$fileInfo = Get-Item $localImagePath
if ($fileInfo.Length -gt 256KB) {
    Write-Error "The downloaded file is larger than 256 KB."
    Remove-Item $localImagePath
    exit 1
}

# Set the downloaded image as the login screen background
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
Set-ItemProperty -Path $registryPath -Name "OEMBackground" -Value 1

# Copy the image to the required location for the login screen background
$destinationImage = "backgroundDefault.jpg"
$destinationDirectory = "C:\Windows\System32\oobe\info\backgrounds"
$destinationPath = "$destinationDirectory\$destinationImage"
if (-not (Test-Path -Path $destinationDirectory)) {
    New-Item -ItemType Directory -Path $destinationDirectory -Force
}
Copy-Item -Path $localImagePath -Destination $destinationPath -Force

# Set the downloaded image as the lock screen background
$lockScreenPath = "C:\Windows\Web\Screen\lockScreen.jpg"
Copy-Item -Path $localImagePath -Destination $lockScreenPath -Force

# Ensure the lock screen registry keys exist
$lockScreenKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
if (-not (Test-Path -Path $lockScreenKey)) {
    New-Item -Path $lockScreenKey -Force
}

# Update the lock screen background setting
Set-ItemProperty -Path $lockScreenKey -Name "LockScreenImagePath" -Value $lockScreenPath
Set-ItemProperty -Path $lockScreenKey -Name "LockScreenImageStatus" -Value 1