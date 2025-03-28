# Import the CSV file
$profileSIDs = Import-Csv -Path "profileSIDs.csv"
$domainSID = (Get-ADDomain).DomainSID.Value
$domainUserProfileSIDs = $profileSIDs | Where-Object {$_.SID -match $domainSID}

# Initialize an array to store the custom objects with SIDs of disabled users
$disabledUserSIDs = @()

# Loop through each SID in the CSV
foreach ($profileSID in $domainUserProfileSIDs) {
    try {
        # Check if the SID matches a disabled AD user account
        $User = Get-ADUser -Identity $($profileSID).SID
        
        # If a match is found, add the custom object with SID to the array
        if (-not $($User.Enabled) -eq $true) {
            Write-Output "SID $($profileSID.SID) belongs to $($User.DistinguishedName)"
            $disabledUserSIDs += [PSCustomObject]@{ SID = $profileSID.SID }
        }
    } catch {
        # If an error occurs, check if it's the specific error we're looking for
        if ($_.FullyQualifiedErrorId -eq "ActiveDirectoryCmdlet:Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException,Microsoft.ActiveDirectory.Management.Commands.GetADUser") {
            # Add the custom object with SID to the array
            Write-Output "SID $($profileSID.SID) belongs to a deleted account."
            $disabledUserSIDs += [PSCustomObject]@{ SID = $profileSID.SID }
        }
    }
}

# Output the list of custom objects with disabled user SIDs
$disabledUserSIDs | Export-Csv -NoTypeInformation -Path "profileSIDs_to_remove.csv"
