# Import the CSV file containing SIDs to remove
$SIDsToRemove = Import-Csv -Path "profileSIDs_to_remove.csv"

# Get the list of local user profiles on the device
$localUserProfiles = Get-CimInstance -Class Win32_UserProfile

# Loop through each local user profile
foreach ($profile in $localUserProfiles) {
    # Check if the SID of the local profile exists in the SIDs to remove
    if ($SIDsToRemove.SID -contains $profile.SID) {
        Write-Output "Removing profile with SID: $($profile.SID)"
        
        # Remove the local user profile
        Remove-CimInstance -InputObject $profile
    }
}
