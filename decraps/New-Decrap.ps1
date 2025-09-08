function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Type,
        [string]$Description,
        [int]$PercentComplete
    )

    Write-Progress -Activity "Applying Registry Tweaks" -Status $Description -PercentComplete $PercentComplete

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type

        $actualValue = (Get-ItemProperty -Path $Path -Name $Name).$Name
        if ($actualValue -eq $Value) {
            Write-Host "✅ [$Description] applied successfully."
        } else {
            Write-Warning "⚠️ [$Description] failed verification. Expected: $Value, Found: $actualValue"
        }
    }
    catch {
        Write-Error "❌ Error applying [$Description]: $_"
    }
}


#set ExecutionPolicy (removing login banner doesn't work without this)
Set-ExecutionPolicy Unrestricted -Force

#disable MS configuration blocker driver
$UCPDStatus = Get-Service ucpd | Select -ExpandProperty Status
If ($UCPDStatus -eq "Running" ) {
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UCPD" -Name "Start" -Value 4 -PropertyType DWORD -Force
	Disable-ScheduledTask -TaskName '\Microsoft\Windows\AppxDeploymentClient\UCPD velocity'
	Write-Warning "UCPD is running, some settings will not apply."
	Restart-Computer -Force
}


$registryTweaks = @(
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Hiberboot (Fast Startup)' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name = 'SearchboxTaskbarMode'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Taskbar Search Button' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowTaskViewButton'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Taskbar Task View Button' },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name = 'AllowNewsAndInterests'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Taskbar News Widget' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarDn'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Taskbar Widgets' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarMn'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Taskbar Widgets and Chat' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.ActionCenter.SmartOptOut'; Name = 'Enabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Suggested Notifications' },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name = 'LockScreenImage'; Value = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'; Type = [Microsoft.Win32.RegistryValueKind]::String; Description = 'Set Lock Screen to Static Built-in Image' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen'; Name = 'LockScreenWidgetsEnabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Windows 11 Lock Screen Feed' },
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings'; Name = 'NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Notifications on Lock Screen (Toasts)' },
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name = 'SubscribedContent-338387Enabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Lock Screen Content Delivery Notifications' },
    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'StartupBoostEnabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Edge Startup Boost (Current User)' },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'StartupBoostEnabled'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Edge Startup Boost (All Users)' },
    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HideRestoreDialogEnabled'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Edge "Restore Pages" Prompt' },
    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'HideFirstRunExperience'; Value = 1; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable Edge First Run Prompt' },
    @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'Wallpaper'; Value = 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'; Type = [Microsoft.Win32.RegistryValueKind]::String; Description = 'Set Desktop Wallpaper to Static Built-in Image' },
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'; Name = '{2cc5ca98-6485-489a-920e-b3e88a6ccce3}'; Value = 0; Type = [Microsoft.Win32.RegistryValueKind]::DWord; Description = 'Disable "About This Image" Desktop Icon' }
)

for ($i = 0; $i -lt $registryTweaks.Count; $i++) {
    $tweak = $registryTweaks[$i]
    $percent = [math]::Round(($i / $registryTweaks.Count) * 100)
    Set-RegistryValue -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type -Description $tweak.Description -PercentComplete $percent
}

Write-Progress -Activity "Applying Registry Tweaks" -Completed -Status "All tweaks processed."


#set power settings
powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
powercfg -change -monitor-timeout-ac 0
powercfg -h off

#refresh after our changes
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters

#unpin store from win11 taskbar
$appname = "Microsoft Store" 
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}

#remove onedrive
Get-Process -Name *onedrive* | Stop-Process -Force 
$32bitOneDrive = "$env:SystemRoot\System32\OneDriveSetup.exe"
$64bitOneDrive = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
If (Test-Path $32bitOneDrive) {Start-Process -FilePath $32bitOneDrive -ArgumentList "/uninstall"}
If (Test-Path $64bitOneDrive) {Start-Process -FilePath $64bitOneDrive -ArgumentList "/uninstall"}
Get-Process -Name explorer | Stop-Process -Force 
#Start-Process -FilePath "$env:SystemRoot\explorer.exe"


#install the Nuget provider and Winget CLI module
Install-PackageProvider -Name NuGet -Confirm:$false -force
find-module microsoft.winget.client | install-module -force
Repair-WinGetPackageManager -Force -Latest
winget source reset --Force


#decrap (this probably needs to be recurring
winget uninstall "Microsoft Teams Meeting Add-in for Microsoft Office" --accept-source-agreements
winget uninstall "Microsoft Update Health Tools" --accept-source-agreements
winget uninstall "PuTTY" --accept-source-agreements
winget uninstall "Microsoft OneDrive" --accept-source-agreements
winget uninstall "Microsoft Clipchamp" --accept-source-agreements
winget uninstall "Microsoft Teams" --accept-source-agreements
winget uninstall "News" --accept-source-agreements
winget uninstall "Microsoft Bing" --accept-source-agreements
winget uninstall "MSN Weather" --accept-source-agreements
winget uninstall "Copilot" --accept-source-agreements
winget uninstall "Xbox" --accept-source-agreements
winget uninstall "Get Help" --accept-source-agreements
winget uninstall "Microsoft 365 Copilot" --accept-source-agreements
winget uninstall "Solitaire & Casual Games" --accept-source-agreements
winget uninstall "Microsoft Sticky Notes" --accept-source-agreements
winget uninstall "Minecraft Education" --accept-source-agreements
winget uninstall "Mixed Reality Portal" --accept-source-agreements
winget uninstall "Mobile Plans" --accept-source-agreements
winget uninstall "Outlook for Windows" --accept-source-agreements
winget uninstall "Microsoft People" --accept-source-agreements
winget uninstall "Microsoft To Do" --accept-source-agreements
winget uninstall "Microsoft Whiteboard" --accept-source-agreements
winget uninstall "Widgets Platform Runtime" --accept-source-agreements
winget uninstall "Dev Home (Preview)" --accept-source-agreements
winget uninstall "Feedback Hub" --accept-source-agreements
winget uninstall "Windows Maps" --accept-source-agreements
winget uninstall "Phone Link" --accept-source-agreements
winget uninstall "Movies & TV" --accept-source-agreements
winget uninstall "Microsoft Family" --accept-source-agreements
winget uninstall "Microsoft.Teams" --accept-source-agreements
winget uninstall "Cross Device Experience Host" --accept-source-agreements
winget uninstall "Mail and Calendar" --accept-source-agreements
winget uninstall "windows web experience pack"
winget uninstall --id Microsoft.549981C3F5F10_8wekyb3d8bbwe
winget uninstall --id Microsoft.MinecraftEducationEdition_8wekyb3d8bbwe
winget uninstall --id Clipchamp.Clipchamp_yxz26nhyzhsrt
winget uninstall --id Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe
winget uninstall --id Microsoft.Windows.DevHome_8wekyb3d8bbwe
winget uninstall --id Microsoft.Messaging_8wekyb3d8bbwe
winget uninstall --id Microsoft.BingNews_8wekyb3d8bbwe
winget uninstall --id Microsoft.BingSearch_8wekyb3d8bbwe
winget uninstall --id Microsoft.Getstarted_8wekyb3d8bbwe
winget uninstall --id Microsoft.YourPhone_8wekyb3d8bbwe



#install Windows Updates
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -Force -ErrorAction 'SilentlyContinue' > $null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
If (Get-InstalledModule -Name PsWindowsUpdate -ErrorAction 'SilentlyContinue') { Update-Module -Name PSWindowsUpdate -Force } Else { Install-Module -Name PSWindowsUpdate -Force }
Import-Module PSWindowsUpdate
Install-WindowsUpdate -NotCategory "Service Packs","FeaturePacks" -NotTitle "preview" -AcceptAll -IgnoreReboot