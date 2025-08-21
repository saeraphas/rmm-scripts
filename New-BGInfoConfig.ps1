# Define the remote file list
$remoteFileList = @(
"https://nocinstallerstorage.blob.core.windows.net/root/BGInfo/Bginfo64.exe"
"https://nocinstallerstorage.blob.core.windows.net/root/BGInfo/Eula.txt"
"https://nocinstallerstorage.blob.core.windows.net/root/BGInfo/nexigen.bgi"
"https://nocinstallerstorage.blob.core.windows.net/root/BGInfo/wallpaper_1920x1080.jpg"
)

# Define the local download directory
$localBasepath = "c:\nexigen"

# Ensure the base path exists
if (-not (Test-Path $localBasePath)) {
    New-Item -ItemType Directory -Path $localBasePath | Out-Null
}

# Save the current progress preference
$originalProgressPreference = $ProgressPreference

# Suppress download progress
$ProgressPreference = 'SilentlyContinue'

# Loop through each remote file URL
foreach ($url in $remoteFileList) {
    # Parse the URL
    $uri = [System.Uri]$url
    $segments = $uri.AbsolutePath.TrimStart('/').Split('/')

    # Find the index of 'root'
    $rootIndex = $segments.IndexOf('root')

    if ($rootIndex -ge 0 -and $rootIndex + 1 -lt $segments.Length) {
        # Get the relative path after 'root' using a range object
        $relativeSegments = $segments[($rootIndex + 1)..($segments.Length - 1)]
        $relativePath = $relativeSegments -join '\'

        # Build the full local file path
        $localFilePath = Join-Path -Path $localBasePath -ChildPath $relativePath

        # Create the directory if it doesn't exist
        $localDir = Split-Path -Path $localFilePath -Parent
        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }

        # Download the file
        Invoke-WebRequest -Uri $url -OutFile $localFilePath -UseBasicParsing
    } else {
        Write-Warning "URL does not contain 'root' directory: $url"
    }
}

# Restore the original progress preference
$ProgressPreference = $originalProgressPreference



$executable = "c:\nexigen\BGInfo\Bginfo64.exe"
$argumentList = @(
"c:\nexigen\BGInfo\nexigen.bgi"
"/TIMER:00"
"/SILENT"
"/NOLICPROMPT"
)
Start-Process -FilePath $executable -ArgumentList $argumentList
