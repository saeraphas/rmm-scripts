
[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    $Splat = @{
        Path        = "HKLM:SOFTWAREPoliciesMicrosoftWindowsWindowsUpdate"
        Name        = @("TargetReleaseVersion", "TargetReleaseVersionInfo")
        ErrorAction = "SilentlyContinue"
    }

    Remove-ItemProperty @Splat -Force
    Remove-ItemProperty -Path "HKLM:SOFTWAREMicrosoftWindowsUpdateUXSettings" -Name "SvOfferDeclined" -Force -ErrorAction SilentlyContinue
    $TargetResult = Get-ItemProperty @Splat
    $OfferResult = Get-ItemProperty -Path "HKLM:SOFTWAREMicrosoftWindowsUpdateUXSettings" -Name "SvOfferDeclined" -ErrorAction SilentlyContinue
    if ($null -ne $TargetResult -or $null -ne $OfferResult) {
        Write-Host "Failed to enable Windows 11 Upgrade."
        exit 1
    }
    exit 0
}

$WebClient = New-Object System.Net.WebClient

# URL to Windows 11 Update Assistant
$Win11UpgradeURL = "https://go.microsoft.com/fwlink/?linkid=2171764"
$UpgradePath = "$env:TEMP\Windows11InstallationAssistant.exe"
$WebClient.DownloadFile($Win11UpgradeURL, $UpgradePath)

Start-Process -FilePath $UpgradePath -ArgumentList "/Install  /MinimizeToTaskBar /QuietInstall /SkipEULA"
end {}