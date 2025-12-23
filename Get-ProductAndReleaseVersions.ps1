# RMM‑provided variables (names now match registry keys, prefixed with rmm_)
param (
    $rmm_ProductVersion = "not set",
    $rmm_TargetReleaseVersionInfo = "not set"
)

# RMM‑expected result variables (strings: "true", "false", or "not set")
$result_targetProductVersion = "not set"
$result_targetReleaseVersionInfo = "not set"

# Registry paths
$wuKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# Initialize registry read variables
$reg_ProductVersion = "not set"
$reg_TargetReleaseVersionInfo = "not set"

# Helper function to safely read registry values
function Get-RegValue {
    param(
        [string]$Path,
        [string]$Name
    )
    try {
        $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        return $item.$Name
    }
    catch {
        return "not set"
    }
}

# Read registry values
$reg_ProductVersion = Get-RegValue -Path $wuKeyPath -Name "ProductVersion"
$reg_TargetReleaseVersionInfo = Get-RegValue -Path $wuKeyPath -Name "TargetReleaseVersionInfo"

# Compare registry values to RMM‑provided values
if ($reg_ProductVersion -ne "not set" -and $reg_ProductVersion -eq $rmm_ProductVersion) {
    $result_targetProductVersion = "true"
} else {
    $result_targetProductVersion = "false"
}

if ($reg_TargetReleaseVersionInfo -ne "not set" -and $reg_TargetReleaseVersionInfo -eq $rmm_TargetReleaseVersionInfo) {
    $result_targetReleaseVersionInfo = "true"
} else {
    $result_targetReleaseVersionInfo = "false"
}


Write-Output "Product Version (RMM): $rmm_ProductVersion"
Write-Output "Product Version (Registry): $reg_ProductVersion"
Write-Output "Product Versions Match: $result_targetProductVersion"

Write-Output "Target Release Version Info (RMM): $rmm_TargetReleaseVersionInfo"
Write-Output "Target Release Version Info (Registry): $reg_TargetReleaseVersionInfo"
Write-Output "Target Release Versions Match: $result_targetReleaseVersionInfo"
