# Prompt for the remote computer name
$remoteComputer = Read-Host -Prompt "Enter the remote computer name"

# Collect the list of local user profile SIDs on the remote computer
$profileSIDs = Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
    Get-CimInstance -Class Win32_UserProfile | Select-Object -Property SID
}

# Output the list of profile SIDs
$profileSIDs
