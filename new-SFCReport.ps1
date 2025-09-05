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
$RMMStatus = $null
$RMMDetail = "SFC log not yet parsed."

function checkReportAge {
    Write-Verbose "Checking whether new scan should run based on SFC log age."
    $SFCRunThresholdDays = 30 
    $today = Get-Date
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $dateDiff = ($today - $lastModifiedDate).Days
    Write-Verbose "SFC log is $dateDiff days old."
    if ($dateDiff -gt $SFCRunThresholdDays) {
        Write-Verbose "Continuing."
        startSFC
    }
    else { 
        Write-Verbose "Exiting."
        exit 
    }
}

function checkReboot {
    Write-Verbose "Checking whether the device has been restarted since last scan."
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $lastBootupTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $rebootedSinceLastRun = ($lastBootupTime -gt $lastModifiedDate)
    Write-Verbose "Last scan time: $lastModifiedDate"
    Write-Verbose "Last reboot time: $lastBootupTime"
    Write-Verbose "Device has been restarted since last scan: $rebootedSinceLastRun."
    if ($rebootedSinceLastRun ) {
        Write-Verbose "Continuing."
        startSFC
    }
    else { 
        Write-Verbose "Exiting."
        exit 
    }
}

function checkStorage {
    Write-Verbose "Checking whether processing should be delayed based on presence of virtual disks."
    $sleepTimeMaxMinutes = 30
    $diskManufacturer = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq '0' } | Select-Object -ExpandProperty Manufacturer
    if ($null -eq $diskManufacturer) { $diskManufacturer = "not specified" }
    $sleepTimeSeconds = (Get-Random -Minimum 0 -Maximum (60 * $sleepTimeMaxMinutes))
    Write-Verbose "Disk manufacturer is $diskManufacturer."
    switch ($diskManufacturer) {
        { $diskManufacturer -eq "Msft" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        { $diskManufacturer -eq "VMware" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        Default { Write-Verbose "Continuing." }
    }
}

Function startSFC {
    Write-Verbose "Starting new SFC scan."
    checkStorage
    Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -RedirectStandardOutput $SFCLog -Wait -WindowStyle Hidden
}

Write-Verbose "Checking for existing SFC log file."
$fileExists = Test-Path -Path $SFCLog

if (-not $fileExists) {
    Write-Verbose "Existing SFC log file NOT found."
    startSFC
} else {
    Write-Verbose "Checking SFC log for matching statuses."

    $statusGoodStrings = @(
        "Windows Resource Protection did not find any integrity violations.",
        "Protección de recursos de Windows no encontró ninguna infracción"
    )
    $statusRetryStrings = @(
        "Windows Resource Protection found corrupt files and successfully repaired them.",
        "Protección de recursos de Windows encontró archivos corruptos y los reparó correctamente."
    )
    $statusRebootPendingStrings = @(
        "There is a system repair pending which requires a reboot to complete.",
        "Hay una reparación del sistema pendiente que requiere reiniciar para completarla."
    )
    $statusFailStrings = @(
        "Windows Resource Protection found corrupt files but was unable to fix some of them.",
        "Protección de recursos de Windows encontró archivos corruptos pero no pudo corregir algunos de ellos.",
        "Windows Resource Protection could not start the repair service.",
        "SFC log does not contain a matching status."
        "SFC log does not exist."
    )

    $allStatusStrings = $statusGoodStrings + $statusRetryStrings + $statusRebootPendingStrings + $statusFailStrings

# Read and filter lines
$log = Get-Content -Path $SFCLog -Encoding Unicode 

#since the output of SFC is line-wrapped, we need to join the lines into a single line first, then parse it.
$singleLineLog = ($log -join ' ') -replace '\s+', ' '

#now we can split the output into separate lines based on the period followed by a capital letter pattern.
$multilinelog = $singleLineLog -replace '\.(?=\s+[A-Z])', ".`n"

#now we can filter the output to discared lines that begin with "Verification"
$filteredLog = $multilinelog | Where-Object { $_ -notmatch '^\s*Verification' -and $_ -ne '' }

$filteredLog
exit


# Initialize result list
    $logSummary = @()

    # Search for each status string
    foreach ($status in $allStatusStrings) {
        if ($logContent -match [regex]::Escape($status) + '.*?\.') {
            $logSummary += $matches[0]
        }
    }
    
    Write-Verbose "SFC log status summary: $logSummary"
    Write-Verbose "Checking whether new scan should run based on SFC log status summary."

    #The RMM service monitor doesn't handle localizations other than US English. 
    #We need to return output from this script as a status code which will actually update the monitor status, as well as a text string for human readable troubleshooting.
    switch ($logSummary) {
        { $null -eq $_ } { $RMMStatus = 1; startSFC } #this will be the case if previous run was interrupted
        { $statusGoodStrings -contains $_ } { $RMMStatus = 0 ; checkReportAge } #run again if the age threshold has been met
        { $statusRetryStrings -contains $_ } { $RMMStatus = 1 ; startSFC } #run again if things were fixed
        { $statusRebootPendingStrings -contains $_ } { $RMMStatus = 1 ; checkReboot } #run again if the device has been restarted since last run
        { $statusFailStrings -contains $_ } { $RMMStatus = 2 } #do nothing, this will generate a ticket
        Default { $RMMStatus = 1 }
    }
}


# Log file should definitely exist at this point, if it does not, return a status that will generate a ticket. 
$fileExists = Test-Path -Path $SFCLog
if (-not $fileExists) {
    $RMMStatus = 2
    $RMMDetail = "SFC log does not exist."
}

Write-Verbose "RMM Status is $RMMStatus." 
Write-Verbose "RMM Detail is $RMMDetail."
#Set-ExecutionPolicy $originalExecutionPolicy
