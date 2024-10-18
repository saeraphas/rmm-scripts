<#
.SYNOPSIS
	This script checks for specific Windows Update registry keys and stores the output to a variable accessible to an RMM agent. 
.DESCRIPTION
	This PowerShell script checks if specific Windows Update settings exist in the registry and retrieves their values. 
    It outputs the values of ProductVersion, TargetReleaseVersion, and TargetReleaseVersionInfo, or indicates if the registry key is missing.
    This script is intended to be run by a RMM service monitor. 
	
.EXAMPLE
	.\Get-TargetReleaseVersionKeys.ps1

.NOTES
    Author:             Douglas Hammond (douglas@douglashammond.com)
	License: 			This script is distributed under "THE BEER-WARE LICENSE" (Revision 42):
						As long as you retain this notice you can do whatever you want with this stuff.
						If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

.LINK
	https://github.com/saeraphas/rmm-scripts
#>

#Requires -Version 4.0

# Define the registry path
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# Initialize variables
$ProductVersion = "not set"
$TargetReleaseVersion = "not set"
$TargetReleaseVersionInfo = "not set"

# Check if the registry key exists
if (Test-Path $regPath) {
    # Check for each property and set the variable accordingly
    if (Get-ItemProperty -Path $regPath -Name "ProductVersion" -ErrorAction SilentlyContinue) {
        $ProductVersion = (Get-ItemProperty -Path $regPath -Name "ProductVersion").ProductVersion
    }
    if (Get-ItemProperty -Path $regPath -Name "TargetReleaseVersion" -ErrorAction SilentlyContinue) {
        $TargetReleaseVersion = (Get-ItemProperty -Path $regPath -Name "TargetReleaseVersion").TargetReleaseVersion
    }
    if (Get-ItemProperty -Path $regPath -Name "TargetReleaseVersionInfo" -ErrorAction SilentlyContinue) {
        $TargetReleaseVersionInfo = (Get-ItemProperty -Path $regPath -Name "TargetReleaseVersionInfo").TargetReleaseVersionInfo
    }
} else {
    # If the key does not exist, the variables remain "not set"
    Write-Output "Registry key does not exist."
}

# Output the values
Write-Output "ProductVersion: $ProductVersion"
Write-Output "TargetReleaseVersion: $TargetReleaseVersion"
Write-Output "TargetReleaseVersionInfo: $TargetReleaseVersionInfo"

Set-ExecutionPolicy $originalExecutionPolicy
