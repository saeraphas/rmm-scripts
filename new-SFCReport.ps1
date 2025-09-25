<#
.SYNOPSIS
	This script runs SFC against the local system and stores the output to a variable accessible to an RMM agent. 

.DESCRIPTION
	This script runs SFC against the local system and stores the output to a variable accessible to an RMM agent.
    To prevent degrading performance on endpoints, this script will exit immediately if it has produced report output within the last 30 days. 
    To prevent degrading performance on virtual servers, this script will sleep up to 15 minutes before continuing. 
	
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

function checkReportAge {
    $SFCRescanThresholdDays = 30 
    Write-Verbose "Checking whether SFC log age exceeds $SFCRescanThresholdDays day rescan threshold."
    $today = Get-Date
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $dateDiff = ($today - $lastModifiedDate).Days
    Write-Verbose "SFC log is $dateDiff days old."
    $rescanThresholdExceeded = ($dateDiff -gt $SFCRescanThresholdDays)
    if ($rescanThresholdExceeded) {
        Write-Verbose "Running new scan."
        startSFC
    } else { 
        Write-Verbose "Not running new scan." 
    }
}

function checkReboot {
    Write-Verbose "Checking whether this device has been restarted since last scan."
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $lastBootupTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $rebootedSinceLastRun = ($lastBootupTime -gt $lastModifiedDate)
    Write-Verbose "Last scan time: $lastModifiedDate"
    Write-Verbose "Last reboot time: $lastBootupTime"
    Write-Verbose "Device has been restarted since last scan: $rebootedSinceLastRun."
    if ($rebootedSinceLastRun ) {
        Write-Verbose "Running new scan."
        startSFC
    } else { 
        Write-Verbose "Not running new scan."
    }
}

function checkStorage {
    $sleepTimeMaxMinutes = 15
    Write-Verbose "Checking whether to add up to $sleepTimeMaxMinutes minutes delay based on disk manufacturer property."
    $diskManufacturer = Get-PhysicalDisk | Where-Object { $_.DeviceID -eq '0' } | Select-Object -ExpandProperty Manufacturer
    if ($null -eq $diskManufacturer) { $diskManufacturer = "not available" }
    $sleepTimeSeconds = (Get-Random -Minimum 0 -Maximum (60 * $sleepTimeMaxMinutes))
    Write-Verbose "Disk manufacturer is $diskManufacturer."
    switch ($diskManufacturer) {
        { $diskManufacturer -eq "Msft" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        { $diskManufacturer -eq "VMware" } { Write-Verbose "Sleeping for $sleepTimeMaxMinutes minutes." ; Start-Sleep -Seconds $sleepTimeSeconds }
        Default { Write-Verbose "Not sleeping based on disk manufacturer property $diskManufacturer." }
    }
}

Function startSFC {
    Write-Verbose "Starting new SFC scan."
    checkStorage
    Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -RedirectStandardOutput $SFCLog -Wait -WindowStyle Hidden
}


$provider = "Nexigen"
$SFCLog = "C:\$($provider)\SFC.txt"
$RMMStatus = 0
$RMMDetail = "SFC log not yet parsed."

# Let's check to see whether the directory exists.  
Write-Verbose "Checking for existing SFC log directory."
$directory = Split-Path -Path $SFCLog -Parent
$directoryExists = Test-Path -Path $directory
# If it doesn't exist, create it.
if (-not $directoryExists) {     
    Write-Verbose "Existing SFC log directory NOT found."       
    try {
        Write-Verbose "Attempting to create directory $directory."
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    } catch {
        # If there is an error, return a status that will generate a ticket.
        Write-Verbose "Error creating directory $directory. $_"
        $RMMStatus = 2
        $RMMDetail = "Error creating directory for SFC log."
    }
}

# Let's check whether we can create the log file. 
Write-Verbose "Checking for existing SFC log file."
$fileExists = Test-Path -Path $SFCLog
# If it doesn't exist, create it.
if (-not $fileExists) {
    Write-Verbose "Existing SFC log file NOT found."
    try {
        Write-Verbose "Attempting to create SFC log file $SFCLog."
        New-Item -Path $SFCLog -ItemType File -Value "SFC scan not yet run." -Force | Out-Null
    } catch {
        # If there is an error, return a status that will generate a ticket.
        Write-Verbose "Error creating SFC log file $SFCLog. $_"
        $RMMStatus = 2
        $RMMDetail = "Error creating SFC log file."
    }
}

# Let's check the log file contents if we haven't already decided to return an error.
# The log file contains a lot of extraneous information, so we will filter and reformat it before we start checking for statuses. 
if ($RMMStatus -eq 0) {

    # Read and filter lines
    $log = Get-Content -Path $SFCLog -Encoding Unicode 

    # Join the entire log into a single line
    $singleLineLog = $log -join ' '

    # Replace duplicated whitespace characters with a single space
    $singleLineLog = $singleLineLog -replace '\s{2,}', ' '

    # Split the output into lines again, at each period followed by whitespace
    $multilinelog = $singleLineLog -replace '\.(?=[ \t])', ".`r`n"

    # Remove leading whitespace from each line
    $multilinelog = ($multilinelog -split "`r`n") | ForEach-Object { $_ -replace '^[ \t]+', '' }

    #now we can filter the output to discared lines that begin with "Verification"
    $filteredLog = $multilinelog | Where-Object { $_ -notmatch '^\s*Verification' -and $_ -ne '' }

    # Let's define the statuses we recognize and categorize them.
    Write-Verbose "Comparing SFC log for matching statuses."

    $statusGoodStrings = @(
        "Windows Resource Protection did not find any integrity violations.",
        "Protección de recursos de Windows no encontró ninguna infracción"
    )
    $statusRescanStrings = @(
        "SFC scan not yet run.",
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
        "Protección de recursos de Windows no pudo iniciar el servicio de reparación.",
        "Windows Resource Protection could not perform the requested operation.",
        "Protección de recursos de Windows no pudo realizar la operación solicitada."
    )

    $allStatusStrings = $statusGoodStrings + $statusRescanStrings + $statusRebootPendingStrings + $statusFailStrings

    # Let's check each of the status strings against the lines in the filtered log and store any matches in a summary array.
    $matchFound = $allStatusStrings | Where-Object { $filteredLog -match $_ }
    if ($matchFound.Count -gt 0) {
        $RMMDetail = $matchFound -join "; "
        $matchFound | ForEach-Object { Write-Verbose "Matched status: $_" }

        # now let's choose an action based on the status we found.
        switch ($matchFound) {
            { $statusGoodStrings -contains $_ } { $RMMStatus = 0 ; checkReportAge } # check the age of the log file to determine whether to run again
            { $statusRescanStrings -contains $_ } { $RMMStatus = 1 ; startSFC } # run again immediately
            { $statusRebootPendingStrings -contains $_ } { $RMMStatus = 1 ; checkReboot } # check the time of last reboot to determine whether to run again
            { $statusFailStrings -contains $_ } { $RMMStatus = 2 } # return a status that will generate a ticket
            Default { $RMMStatus = 2 } # return a status that will generate a ticket
        }
    } else {
        $RMMDetail = "SFC log does not contain a matching status."
        Write-Verbose $RMMDetail
        $RMMStatus = 2 # return a status that will generate a ticket
        startSFC
    }
}

#temporary workaround for RMM service monitor only checking for english localization
if ($statusGoodStrings -contains $RMMDetail ) { $output = "Windows Resource Protection did not find any integrity violations." } else {$output -eq $RMMDetail}

Write-Verbose "RMM Status is $RMMStatus." 
Write-Verbose "RMM Detail is $RMMDetail"

Set-ExecutionPolicy $originalExecutionPolicy
