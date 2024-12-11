

<#
.SYNOPSIS
Sets a login banner on Windows desktops and servers.

.DESCRIPTION
This script sets the required registry keys to display a login banner on Windows desktops and servers. The banner will be shown to users when they log in, displaying a custom message.

.PARAMETER
None

.EXAMPLE
.\New-LoginBanner.ps1

#>

[CmdletBinding()]
param ()


#$NewLine = [Environment]::NewLine
$OrganizationName = "Nexigen Communications, LLC"
$legalnoticecaption = "NOTICE"
$DisclaimerBlock = @'
You are accessing a ORGANIZATIONNAME protected computer system that contains proprietary and confidential information. Only authorized users may access this resource. By continuing to use this system, you agree to the following terms.

No Expectation of Privacy:  You have no expectation of privacy on this system. All communications and activities are subject to monitoring, interception, and recording for purposes including, but not limited to, security analysis, system diagnostics, and investigations into misuse or misconduct.

Consent to Monitoring and Inspection: By using this system, you consent to the monitoring, interception, and seizure of all communications and data on this system or any attached devices for any authorized purpose.

Legal Protections and Confidentiality: Determinations regarding the privilege or confidentiality of any communication or data are made in accordance with legal standards. If you need to rely on any legal privilege or confidentiality protections, you should seek independent legal advice before using this system.

Legal Consequences: Unauthorized use or misuse of this system will result in prosecution to the fullest extent of the law.

If you are not an authorized user, please disconnect immediately. 
'@

# Replace the placeholder with the organization name
$legalnoticetext = $disclaimerBlock -replace "ORGANIZATIONNAME", $organizationName

try {
    # Get the current login banner text
    $currentBanner = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticetext" -ErrorAction SilentlyContinue

    if ($currentBanner.legalnoticetext -ne $legalnoticetext) {
        # Set the registry keys for the login banner
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticecaption" -Value $legalnoticecaption
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticetext" -Value $legalnoticetext

        Write-Verbose "Login banner has been set successfully."
    } else {
        Write-Verbose "The login banner is already set to the desired value."
    }
} catch {
    Write-Error "An error occurred while setting the login banner: $_"
}