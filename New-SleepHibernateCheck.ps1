<#
.SYNOPSIS
Checks the current power profile settings for sleep and AC power.

.DESCRIPTION
This script retrieves the GUID of the current active power profile and queries the sleep and hibernate settings. It extracts the Current AC Power Setting Index, converts the hex values to decimal, and checks if the settings are enabled.
#>

# Get the GUID of the current active power profile using powercfg
$planGuid = (powercfg /getactivescheme | Select-String -Pattern "GUID: (.*) \(").Matches.Groups[1].Value.Trim()

# Run the powercfg commands and store the output
$sleepSettings = powercfg /query $planGuid SUB_SLEEP STANDBYIDLE
$hibernateSettings = powercfg /query $planGuid SUB_SLEEP HIBERNATEIDLE

# Function to extract and convert the Current AC Power Setting Index
function Get-ACPowerSettingIndex {
    param (
        [string]$settingsOutput
    )
    $hexValue = ($settingsOutput | Select-String -Pattern "Power Setting Index: (0x[0-9A-F]+)").Matches.Groups[1].Value
    [convert]::ToInt32($hexValue, 16)
}

# Extract and convert the settings
$acSleepIndex = Get-ACPowerSettingIndex -settingsOutput $sleepSettings
$acHibernateIndex = Get-ACPowerSettingIndex -settingsOutput $hibernateSettings

# Check if the values are equal to 0
$acSleepEnabled = $acSleepIndex -ne 0
$acHibernateEnabled = $acHibernateIndex -ne 0

# Display the results
#Write-Output "AC Sleep Enabled: $acSleepEnabled"
#Write-Output "AC Hibernate Enabled: $acHibernateEnabled"