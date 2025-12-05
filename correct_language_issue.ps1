<#
Use: Run as Administrator to fix garbled Chinese text in installers by switching non-Unicode/system locale and related settings to zh-CN.
Reboot is required for full effect.
#>

# Stop on first error so the script fails fast.
$ErrorActionPreference = 'Stop'

# Ensure we are running elevated.
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error 'Please run this script from an elevated PowerShell session (Run as administrator).'
    exit 1
}

# Target locale values.
$targetCulture = 'zh-CN'
$targetGeoId = 45  # China

# Apply settings relevant to non-Unicode apps and UI language.
Set-WinSystemLocale -SystemLocale $targetCulture
Set-Culture -CultureInfo $targetCulture
Set-WinUILanguageOverride -Language $targetCulture
Set-WinHomeLocation -GeoId $targetGeoId

Write-Host 'Locale settings applied. Please reboot Windows to complete the change.' -ForegroundColor Green
