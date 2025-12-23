# RMM‑provided variables (names now match registry keys, prefixed with rmm_)
param (
    $rmm_ProductVersion = "not set",
    $rmm_TargetReleaseVersionInfo = "not set"
)

# Registry paths
$wuKeyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# Ensure the WindowsUpdate key exists
if (-not (Test-Path $wuKeyPath)) {
    New-Item -Path $wuKeyPath -Force | Out-Null
}

# Set TargetReleaseVersion (DWORD = 1)
New-ItemProperty -Path $wuKeyPath -Name "TargetReleaseVersion" -Value 1 -PropertyType DWord -Force | Out-Null

# Set ProductVersion (REG_SZ)
New-ItemProperty -Path $wuKeyPath -Name "ProductVersion" -Value $rmm_ProductVersion -PropertyType String -Force | Out-Null

# Set TargetReleaseVersionInfo (REG_SZ)
New-ItemProperty -Path $wuKeyPath -Name "TargetReleaseVersionInfo" -Value $rmm_TargetReleaseVersionInfo -PropertyType String -Force | Out-Null

