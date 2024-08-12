<#
.SYNOPSIS
	This script runs SFC against the local system and stores the output to a variable accessible to an RMM agent. 

.DESCRIPTION
	This script 
	
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

$provider = "Nexigen"
$SFCRunThresholdDays = 30 
$SFCLog = "C:\$($provider)\SFC.txt"

function checkReportAge {
    $today = Get-Date
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $dateDiff = ($today - $lastModifiedDate).Days
    if ($dateDiff -gt $SFCRunThresholdDays) { return $true } else { exit }
}

function checkStorage {
    $diskMake = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq '0' } | Select-Object -ExpandProperty Manufacturer
    $sleepTimeMaxMinutes = 1
    $sleepTimeSeconds = (Get-Random -Minimum 0 -Maximum (60 * $sleepTimeMaxMinutes))
    switch ($diskMake) {
        { $diskMake -eq "Msft" } { Write-Verbose "Sleeping for $sleepTimeSeconds." ; Start-Sleep -Seconds $sleepTimeSeconds; return $true }
        { $diskMake -eq "VMware" } { Write-Verbose "Sleeping for $sleepTimeSeconds." ; Start-Sleep -Seconds $sleepTimeSeconds; return $true }
        Default { return $true }
    }
}

function checkOutput {
    param (
        $output
    )
    switch ($output) {
        { $null -eq $_ } { startSFC } #this will be the case if previous run was interrupted 
        { $_ -match "Windows Resource Protection did not find any integrity violations." } { exit } #no need to run if last output was OK
        { $_ -match "Windows Resource Protection found corrupt files and successfully repaired them." } { startSFC } #run again if things were fixed
        Default { startSFC }
    }
}

Function startSFC {
    Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -RedirectStandardOutput $SFCLog -Wait -WindowStyle Hidden
}

$fileExists = Test-Path -Path $SFCLog

if ($fileExists) {
    $output = Get-Content -Path $SFCLog -Encoding unicode | Where-Object { $_ -match "Windows Resource Protection" } | Select-Object -First 1
    checkReportAge
    checkStorage
    checkOutput $output   
} else {
    checkStorage
    startSFC
}

$output = Get-Content -Path $SFCLog -Encoding unicode | Where-Object { $_ -match "Windows Resource Protection" } | Select-Object -First 1

#et-ExecutionPolicy $originalExecutionPolicy
