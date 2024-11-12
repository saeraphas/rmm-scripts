<#
.SYNOPSIS
	This script runs SFC against the local system and stores the output to a variable accessible to an RMM agent. 

.DESCRIPTION
	This script runs SFC against the local system and stores the output to a variable accessible to an RMM agent.
    To prevent degrading performance on endpoints, this script will exit immediately if it has produced report output within the last 30 days. 
    To prevent degrading performance on virtual servers, this script will sleep between 1 and 60 minutes before continuing. 
	
.EXAMPLE
	.\new-SFCReport.ps1

.NOTES
    Author:             Douglas Hammond (douglas@douglashammond.com)
	License: 			This script is distributed under "THE BEER-WARE LICENSE" (Revision 42):
						As long as you retain this notice you can do whatever you want with this stuff.
						If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.

.LINK
	https://github.com/saeraphas/rmm-scripts
#>
#Requires -Version 4.0
[CmdletBinding()]
param()

$provider = "Nexigen"
$SFCLog = "C:\$($provider)\SFC.txt"
$output = "SFC log not yet parsed."

function checkReportAge {
    Write-Verbose "Checking whether new scan should run based on SFC log age."
    $SFCRunThresholdDays = 30 
    $today = Get-Date
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $dateDiff = ($today - $lastModifiedDate).Days
    Write-Verbose "SFC log is $dateDiff days old."
    if ($dateDiff -gt $SFCRunThresholdDays) {
        Write-Verbose "Continuing."
    } else { 
        Write-Verbose "Exiting."
        exit 
    }
}

function checkStorage {
    Write-Verbose "Checking whether processing should be delayed based on presence of virtual disks."
    $sleepTimeMaxMinutes = 30
    $diskMake = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq '0' } | Select-Object -ExpandProperty Manufacturer
    $sleepTimeSeconds = (Get-Random -Minimum 0 -Maximum (60 * $sleepTimeMaxMinutes))
    switch ($diskMake) {
        { $diskMake -eq "Msft" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        { $diskMake -eq "VMware" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        Default {Write-Verbose "Continuing."}
    }
}

function checkOutput {
    param (
        $output
    )
    Write-Verbose "Checking whether new scan should run based on SFC log status summary."
    switch ($output) {
        { $null -eq $_ } { startSFC } #this will be the case if previous run was interrupted 
        { $_ -match "Windows Resource Protection did not find any integrity violations." } { Write-Verbose "Exiting."; exit } #no need to run if last output was OK
        { $_ -match "Windows Resource Protection found corrupt files and successfully repaired them." } { startSFC } #run again if things were fixed
        { $_ -match "There is a system repair pending which requires reboot to complete." } { Write-Verbose "Exiting."; exit } #no need to re-run if waiting on reboot
        Default { checkReportAge }
    }
}

Function startSFC {
    Write-Verbose "Starting new SFC scan."
    Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -RedirectStandardOutput $SFCLog -Wait -WindowStyle Hidden
}

function readSFCLog {
    param (
        $SFCLog
    )
    Write-Verbose "Checking SFC log for matching statuses."
    $StatusSummary = Get-Content -Path $SFCLog -Encoding unicode | Where-Object { $_ -match "Windows Resource Protection" -or $_ -match "system repair pending" } | Select-Object -First 1
    if ($null -eq $StatusSummary){$StatusSummary = "SFC log does not contain a matching status."}
    Write-Verbose "Status Summary: $StatusSummary"
    return $StatusSummary
}

Write-Verbose "Checking for existing SFC log file."
$fileExists = Test-Path -Path $SFCLog

if ($fileExists) {
    Write-Verbose "Existing SFC log file found."
    checkStorage
    $output = readSFCLog($SFCLog)
    checkOutput($output)
} else {
    Write-Verbose "Existing SFC log file NOT found."
    checkStorage
    startSFC
    $output = readSFCLog($SFCLog)
}

Set-ExecutionPolicy $originalExecutionPolicy
