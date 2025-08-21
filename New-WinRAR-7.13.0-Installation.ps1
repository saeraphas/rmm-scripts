#installer/updater
$WinRARInfo = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "WinRAR*"} | Select-Object DisplayName, DisplayVersion
if ($WinRARInfo.DisplayVersion -ne "7.13.0") {
$remoteurl = "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-713.exe"
$localpath = "c:\nexigen\WinRAR\WinRAR-713.exe"
$folderPath = Split-Path $localpath
if (-not (Test-Path $folderPath)) { New-Item -ItemType Directory -Path $folderPath -Force }
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $remoteurl -OutFile $localpath
Start-Sleep -Seconds 5
$InstallerArguments = "/S"
Start-Process $localpath -ArgumentList $InstallerArguments
Start-Sleep -Seconds 5
}
$WinRARInfo = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {$_.DisplayName -like "WinRAR*"} | Select-Object DisplayName, DisplayVersion
$WinRARInfo
