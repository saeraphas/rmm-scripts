
$dir = "c:\Petauri"
$dirExists = Test-Path -Path $dir
If (-not ($dirExists)){New-Item $dir -ItemType Directory -force}
$url = "https://nocinstallerstorage.blob.core.windows.net/root/Brightly/Petauri_Agent/Windows/Agent_Install.msi"
$file = "$($dir)\Agent_Install.msi"
Invoke-WebRequest -Uri $url -outfile $file 

$url2 = "https://nocinstallerstorage.blob.core.windows.net/root/Brightly/Petauri_Agent/Windows/Agent_Install.mst"
$file2 = "$($dir)\Agent_Install.mst"
Invoke-WebRequest -Uri $url2 -outfile $file2

$FileExists = Test-Path -Path $file
$File2Exists = Test-Path -Path $file2

$argumentlist = @(
"/i"
"`"$file`""
"TRANSFORMS=`"$file2`""
)

Write-Output $argumentlist
If ($FileExists -and $File2Exists) {Start-Process msiexec -ArgumentList $argumentlist}

