#set ExecutionPolicy (removing login banner doesn't work without this)
Set-ExecutionPolicy Unrestricted -Force


#disable MS configuration blocker driver
$UCPDStatus = Get-Service ucpd | Select -ExpandProperty Status
If ($UCPDStatus -eq "Running" ) {
	New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\UCPD" -Name "Start" -Value 4 -PropertyType DWORD -Force
	Disable-ScheduledTask -TaskName '\Microsoft\Windows\AppxDeploymentClient\UCPD velocity'
	Write-Warning "UCPD is running, some settings will not apply."
}


#set power settings
powercfg -change -standby-timeout-ac 0
powercfg -change -hibernate-timeout-ac 0
powercfg -change -monitor-timeout-ac 0
powercfg -h off


#disable hiberboot
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Value 0


#set the desktop wallpaper to a static builtin and disable the about-this-image desktop icon
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Type "String" -Value "C:\Windows\Web\Wallpaper\Windows\img0.jpg" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{2cc5ca98-6485-489a-920e-b3e88a6ccce3}" -Type "DWord" -Value 0 -Force
RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters


#disable showing taskbar search button 
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Type "DWord" -Value 0 -Force


#disable showing taskbar task view button
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Type "DWord" -Value 0 -Force


#disable showing all widgets (blocked by UCPD)
if ($UCPDStatus -eq "Stopped") {Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Type "DWord" -Value 0 -Force}


#disable showing taskbar News widget
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Force


#disable showing taskbar widgets
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDn" -Type "DWord" -Value 0 -Force


#disable showing taskbar Widgets and Chat
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Type "DWord" -Value 0 -Force


#disable "suggested" notifications
#Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.ActionCenter.SmartOptOut' -Name 'Enabled' -Value 0 -Force
$registryKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.ActionCenter.SmartOptOut'
$propertyName = "Enabled"
$propertyValue = "0"
$propertyType = "DWord"
if (-not (Test-Path $registryKeyPath)) { New-Item -Path $registryKeyPath -Force }
Set-ItemProperty -Path $registryKeyPath -Name $propertyName -Value $propertyValue -Type $propertyType -Force


#unpin store from win11 taskbar
$appname = "Microsoft Store" 
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $appname}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}


#Set the Lock Screen to a static builtin
$registryKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
$propertyName = "LockScreenImage"
$propertyValue = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
$propertyType = "String"
if (-not (Test-Path $registryKeyPath)) { New-Item -Path $registryKeyPath -Force }
Set-ItemProperty -Path $registryKeyPath -Name $propertyName -Value $propertyValue -Type $propertyType -Force


#disable win11 lock screen feed
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lock Screen" -Name "LockScreenWidgetsEnabled" -Value 0

#disable notifications on the lock screen
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings" -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Type "DWord" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -Type "DWord" -Value 0 -Force


#disable edge startup boost
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Type "DWord" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Type "DWord" -Value 0 -Force


#disable edge "restore pages" prompt
$registryKeyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Edge\"
$propertyName = "HideRestoreDialogEnabled"
$propertyValue = "1"
$propertyType = "DWord"
if (-not (Test-Path $registryKeyPath)) { New-Item -Path $registryKeyPath -Force }
Set-ItemProperty -Path $registryKeyPath -Name $propertyName -Value $propertyValue -Type $propertyType -Force


#disable edge first run prompt
$registryKeyPath = "HKCU:\SOFTWARE\Policies\Microsoft\Edge\"
$propertyName = "HideFirstRunExperience"
$propertyValue = "1"
$propertyType = "DWord"
if (-not (Test-Path $registryKeyPath)) { New-Item -Path $registryKeyPath -Force }
Set-ItemProperty -Path $registryKeyPath -Name $propertyName -Value $propertyValue -Type $propertyType -Force


#make the Nexigen directory
$path = "C:\Nexigen"
if (-not (Test-Path $path)){ New-Item -ItemType Directory -Path $path -Force }


#set $dashboardBookmark to the team board you want below
#Team 1 Display -- https://nexigen.brightgauge.co/dashboards/63df5b43-61a6-4797-bb56-5644a8aa9df1/
#Team 2 Display -- https://nexigen.brightgauge.co/dashboards/8a5973ce-44c4-459c-ac48-288430991eba/
#Service Desk "https://nexigen.brightgauge.co/dashboards/a6ac210c-a389-11e7-aba9-0a23584d9728/"
#NOC board "https://nexigen.brightgauge.co/dashboards/ae7fcc3d-d7c3-47f0-8a76-7ad525cb40f3/"
#Operations Performance "https://nexigen.brightgauge.co/dashboards/0216fa13-aa38-48c4-b105-f2617f174928/"
#3CX Wallboard "https://pbx.nexigen.com:5001/#/wallboard"
$dashboardBookmark = "https://nexigen.brightgauge.co/dashboards/0216fa13-aa38-48c4-b105-f2617f174928/"
$scriptpath = "C:\Nexigen\Load_Gauges.cmd"
$scriptContents = @"
taskkill /f /im msedge.exe
"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --start-fullscreen --force-device-scale-factor=1.2 --app $dashboardBookmark
"@
$scriptContents | Out-File -FilePath $scriptpath -Encoding ASCII
$registryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$registryKeyName = "Load_Gauges"
$registryKeyValue = $scriptpath
New-ItemProperty -Path $registryKeyPath -Name $registryKeyName -Value $registryKeyValue -PropertyType "String" -Force


#remove onedrive
Get-Process -Name *onedrive* | Stop-Process -Force 
$32bitOneDrive = "$env:SystemRoot\System32\OneDriveSetup.exe"
$64bitOneDrive = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
If (Test-Path $32bitOneDrive) {Start-Process -FilePath $32bitOneDrive -ArgumentList "/uninstall"}
If (Test-Path $64bitOneDrive) {Start-Process -FilePath $64bitOneDrive -ArgumentList "/uninstall"}
Get-Process -Name explorer | Stop-Process -Force 
#Start-Process -FilePath "$env:SystemRoot\explorer.exe"


#remove the login banner at shutdown time so that the device can log in automatically
$Task = 'C:\Nexigen\Clear-LoginBanner.ps1'
$TaskContents = @'
# Define the registry paths for the login banner
$regPath1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$regPath2 = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
# Define the registry keys for the login banner
$bannerTextKey = "LegalNoticeText"
$bannerCaptionKey = "LegalNoticeCaption"
# Function to clear the login banner
function Clear-LoginBanner {
    param (
        [string]$path,
        [string]$key
    )
    if ((Get-Item $path).property.ToLower() -contains $($key).ToLower()) {
        try {
            Remove-ItemProperty -Path $path -Name $key -ErrorAction Stop
            Write-Output "Successfully cleared $key from $path"
        } catch {
            Write-Output "Failed to clear $key from $path $_"
        }
    } else {
        Write-Output "$key not found in $path"
    }
}
# Check and clear the login banner text and caption
Clear-LoginBanner -path $regPath1 -key $bannerTextKey
Clear-LoginBanner -path $regPath1 -key $bannerCaptionKey
Clear-LoginBanner -path $regPath2 -key $bannerTextKey
Clear-LoginBanner -path $regPath2 -key $bannerCaptionKey
'@
$TaskContents | Out-File -FilePath $Task
$TaskName = "Clear Login Banner"
$User = 'Nt Authority\System'
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File $Task"
$Triggers = @()
$CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
$Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$Trigger.Repetition = "MSFT_TaskRepetitionPattern"
$Trigger.Subscription = 
@"
<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name='User32'] and EventID=1074]]</Select></Query></QueryList>
"@
$Trigger.Enabled = $True 
$Triggers += $Trigger
$Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType ServiceAccount
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries 
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Triggers -Principal $Principal -Settings $Settings


#bginfo (requires manual transfer of bginfo and logo wallpaper)
$registryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$registryKeyName = "NexigenBGInfo"
$registryKeyValue = @'
"C:\Nexigen\BGInfo\Bginfo64.exe" "C:\Nexigen\BGInfo\Nexigen.bgi" /timer:0 /silent /nolicprompt
'@
New-ItemProperty -Path $registryKeyPath -Name $registryKeyName -Value $registryKeyValue -PropertyType "String" -Force
$BGInfoPath = "C:\Nexigen\BGInfo\Bginfo64.exe"
$BGInfoArguments = @("C:\Nexigen\BGInfo\Nexigen.bgi","/timer:0","/silent","/nolicprompt") 
If (Test-Path $BGInfoPath) {Start-Process -FilePath $BGInfoPath -ArgumentList $BGInfoArguments}


#install the Nuget provider and Winget CLI module
Install-PackageProvider -Name NuGet -Confirm:$false -force
find-module microsoft.winget.client | install-module -force


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