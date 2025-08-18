#suppress console errors
$ErrorActionPreference = 'silentlycontinue'

$cleanupLog = "c:\Nexigen\DellCleanup\cleanup.log"
$logDirectory = Split-Path $cleanupLog
if (-not (Test-Path $logDirectory)) { New-Item -ItemType Directory -Path $logDirectory -Force }
Start-Transcript -Path $cleanupLog

$manufacturer = "Dell"

if ($manufacturer -like "*Dell*") {

    $UninstallPrograms = @(
        "Dell SupportAssist OS Recovery Plugin for Dell Update"
        "Dell SupportAssist OS Recovery"
        "Dell SupportAssist Remediation"
        "Dell SupportAssist"
        "Dell SupportAssistAgent"
        "Dell Update - SupportAssist Update Plugin"
        "DellInc.DellSupportAssistforPCs"
        "SupportAssist Recovery Assistant"
    )

    $WhitelistedApps += @(
        "Dell - Extension*"
        "Dell Command | Power Manager"
        "Dell Command | Update for Windows 10"
        "Dell Command | Update for Windows Universal"
        "Dell Command | Update"
        "Dell Core Services"
        "Dell Digital Delivery Service"
        "Dell Digital Delivery"
        "Dell Display Manager 2.0"
        "Dell Display Manager 2.1"
        "Dell Display Manager 2.2"
        "Dell Optimizer Core"
        "Dell Optimizer Service"
        "Dell Optimizer"
        "Dell Pair"
        "Dell Peripheral Manager"
        "Dell Power Manager Service"
        "Dell Power Manager"
        "Dell SupportAssist OS Recovery Plugin for Dell Update"
        "Dell SupportAssist Remediation"
        "Dell, Inc. - Firmware*"
        "DellInc.DellCommandUpdate"
        "DellInc.DellDigitalDelivery"
        "DellInc.DellOptimizer"
        "DellInc.DellPowerManager"
        "DellInc.PartnerPromo"
        "DellOptimizerUI"
        "WavesAudio.MaxxAudioProforDell2019"
    )

    $UninstallPrograms = $UninstallPrograms | Where-Object { $WhitelistedApps -notcontains $_ }

    foreach ($app in $UninstallPrograms) {

        if (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app -ErrorAction SilentlyContinue) {
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online
            Write-Host "Removed provisioned package for $app."
        }
        else {
            Write-Host "Provisioned package for $app not found."
        }

 
        if (Get-AppxPackage -Name $app -ErrorAction SilentlyContinue) {
            Get-AppxPackage -allusers -Name $app | Remove-AppxPackage -AllUsers
            Write-Host "Removed $app."
        }
        else {
            Write-Host "$app not found."
        }

    }

    foreach ($program in $UninstallPrograms) {
        write-host "Calling CIM Win32_Product Uninstall for $program"
        Get-CimInstance -Classname Win32_Product | Where-Object Name -Match $program | Invoke-CimMethod -MethodName UnInstall
    }


    # Dell SupportAssist Remediation
    $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist Remediation" } | Select-Object -Property QuietUninstallString

    ForEach ($sa in $dellSA) {
        If ($sa.QuietUninstallString) {
            try {
                cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    
        }
    }


    # Dell SupportAssist OS Recovery Plugin for Dell Update
    $dellSA = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match "Dell SupportAssist OS Recovery Plugin for Dell Update" } | Select-Object -Property QuietUninstallString

    ForEach ($sa in $dellSA) {
        If ($sa.QuietUninstallString) {
            try {
                cmd.exe /c $sa.QuietUninstallString
            }
            catch {
                Write-Warning "Failed to uninstall Dell Support Assist Remediation"
            }    
        }
    }
 

}
write-host "Completed"

Stop-Transcript