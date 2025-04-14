
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
    $Win11ManualUpgradeLogDirectory = "C:\Nexigen"
    If (-not (Test-Path -Path $Win11ManualUpgradeLogDirectory)) {New-Item -ItemType Directory -Path $Win11ManualUpgradeLogDirectory -Force}
    $Win11ManualUpgradeLogPath = "$Win11ManualUpgradeLogDirectory\Win11Upgrade.log"
    $StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MessageText = "Win11 Upgrade in place attempt starting at $StartTime."
    Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append

    if (-not (Test-IsElevated)) {
        $MessageText = "Access Denied. Please run with Administrator privileges."
        Write-Error -Message $MessageText
        Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
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
        $MessageText = "Failed to enable Windows 11 Upgrade."
        Write-Error $MessageText
        Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
        exit 1
    }

    $WebClient = New-Object System.Net.WebClient

    # URL to Windows 11 Update Assistant
    $Win11UpgradeURL = "https://go.microsoft.com/fwlink/?linkid=2171764"
    $UpgradePath = "$env:TEMP\Windows11InstallationAssistant.exe"
    $Win11UpgradeUtilityExists = Test-Path $UpgradePath
    If (-not $Win11UpgradeUtilityExists) {
        try {
            $WebClient.DownloadFile($Win11UpgradeURL, $UpgradePath)
        }
        catch {
            $MessageText = "Downloading Upgrade Utility from $Win11Upgrade failed."
            Write-Error $MessageText
            Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
        }
    }
    $Win11UpgradeUtilityExists = Test-Path $UpgradePath
    If ($Win11UpgradeUtilityExists) {
        try {
            Start-Process -FilePath $UpgradePath -ArgumentList "/Install /MinimizeToTaskBar /QuietInstall /SkipEULA /copylogs $Win11ManualUpgradeLogDirectory"        
        }
        catch {
            $MessageText = "Starting Upgrade Utility $UpgradePath failed."
            Write-Error $MessageText
            Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
        }
    }
    else {
        $MessageText = "Upgrade Utility not found at $UpgradePath."
        Write-Error $MessageText
        Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
    }
    exit 0
}

end {
    $StopTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $MessageText = "Win11 Upgrade in place attempt finished at $StopTime."
    Write-Output $MessageText | Out-File -FilePath $Win11ManualUpgradeLogPath -Append
}