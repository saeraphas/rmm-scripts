$SFCLog = "C:\rmm\SFC.txt"
$SFCRunThresholdDays = 30 

Function startSFC {
    Start-Process -FilePath "C:\Windows\System32\sfc.exe" -ArgumentList '/scannow' -RedirectStandardOutput $SFCLog -Wait -WindowStyle Hidden
}

$fileExists = Test-Path -Path $SFCLog

if ($fileExists) {
    $today = Get-Date
    $lastModifiedDate = (Get-Item $SFCLog).LastWriteTime
    $dateDiff = ($today - $lastModifiedDate).Days
    if ($dateDiff > $SFCRunThresholdDays) {
        $output = Get-Content -Path $SFCLog -Encoding unicode | Where-Object { $_ -match "Windows Resource Protection" } | Select-Object -First 1
        if ($null -ne $output) {
            startSFC
        }  
    }  
} else {
    startSFC
}

$output = Get-Content -Path $SFCLog -Encoding unicode | Where-Object { $_ -match "Windows Resource Protection" } | Select-Object -First 1

Set-ExecutionPolicy $originalExecutionPolicy
