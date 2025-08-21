
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
