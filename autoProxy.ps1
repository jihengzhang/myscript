# Smart Proxy Configuration Script
# Usage: 
#   .\autoProxy.ps1          - Auto detect and configure proxy
#   .\autoProxy.ps1 -Auto    - Auto detect and configure proxy
#   .\autoProxy.ps1 -Clear   - Force clear proxy settings (direct connection)
#   .\autoProxy.ps1 -Status  - Show current proxy status only (no changes)

param(
    [switch]$Auto,
    [switch]$Clear,
    [switch]$Status
)

$proxyHost = "127.0.0.1"
$proxyPort = 17890
$proxyAddress = "${proxyHost}:${proxyPort}"
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

Write-Host "=== Smart Proxy Configuration ===" -ForegroundColor Cyan

$modeCount = 0
if ($Auto) { $modeCount++ }
if ($Clear) { $modeCount++ }
if ($Status) { $modeCount++ }

if ($modeCount -gt 1) {
    Write-Host "[ERROR] Use only one mode at a time: -Auto, -Clear, or -Status." -ForegroundColor Red
    exit 1
}

# Default mode is Status when no switch is provided.
if (-not $Auto -and -not $Clear -and -not $Status) {
    $Status = $true
}

function Test-ProxyListening {
    param(
        [string]$HostName,
        [int]$Port
    )

    $isListening = $false
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connection = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne(1000, $false)
        if ($wait -and $tcpClient.Connected) {
            $isListening = $true
        }
        $tcpClient.Close()
    } catch {
        $isListening = $false
    }

    return $isListening
}

$listening = Test-ProxyListening -HostName $proxyHost -Port $proxyPort

if ($Status) {
    Write-Host "Mode: Status (read-only)" -ForegroundColor Yellow
    $proxy = Get-ItemProperty -Path $regPath
    $proxyEnable = if ($null -ne $proxy.ProxyEnable) { $proxy.ProxyEnable } else { 0 }
    $proxyServer = if ($null -ne $proxy.ProxyServer) { $proxy.ProxyServer } else { "(not set)" }
    $autoConfig = if ($null -ne $proxy.AutoConfigURL) { $proxy.AutoConfigURL } else { "(not set)" }
    $autoDetect = if ($null -ne $proxy.AutoDetect) { $proxy.AutoDetect } else { 0 }
    $proxyOverride = if ($null -ne $proxy.ProxyOverride) { $proxy.ProxyOverride } else { "(not set)" }
    $httpProxy = if ($env:HTTP_PROXY) { $env:HTTP_PROXY } else { "(not set)" }
    $httpsProxy = if ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } else { "(not set)" }
    $allProxy = if ($env:ALL_PROXY) { $env:ALL_PROXY } else { "(not set)" }

    $winHttpRaw = (netsh winhttp show proxy | Out-String)
    $winHttpDirect = $winHttpRaw -match "Direct access \(no proxy server\)"

    $manualProxyOn = ($proxyEnable -eq 1) -and ($proxyServer -ne "(not set)")
    $pacOn = ($autoConfig -ne "(not set)")
    $autoDetectOn = ($autoDetect -eq 1)
    $winInetProxyConfigured = $manualProxyOn -or $pacOn -or $autoDetectOn
    $usesLocalProxyAddress = ($proxyServer -match "127\.0\.0\.1:17890") -or ($autoConfig -match "127\.0\.0\.1:17890")

    Write-Host "" 
    Write-Host "[System Proxy - WinINet]" -ForegroundColor Cyan
    Write-Host "Port ${proxyAddress} listening: $listening" -ForegroundColor Gray
    Write-Host "ProxyEnable: $proxyEnable" -ForegroundColor Gray
    Write-Host "ProxyServer: $proxyServer" -ForegroundColor Gray
    Write-Host "AutoConfigURL: $autoConfig" -ForegroundColor Gray
    Write-Host "AutoDetect: $autoDetect" -ForegroundColor Gray
    Write-Host "ProxyOverride: $proxyOverride" -ForegroundColor Gray

    Write-Host "" 
    Write-Host "[UI Mapping]" -ForegroundColor Cyan
    Write-Host "Use a proxy server (Manual): $(if ($manualProxyOn) { 'On' } else { 'Off' })" -ForegroundColor Gray
    Write-Host "Use setup script (PAC): $(if ($pacOn) { 'On' } else { 'Off' })" -ForegroundColor Gray
    Write-Host "Automatically detect settings: $(if ($autoDetectOn) { 'On' } else { 'Off' })" -ForegroundColor Gray

    Write-Host "" 
    Write-Host "[WinHTTP Proxy]" -ForegroundColor Cyan
    Write-Host ($winHttpRaw.Trim()) -ForegroundColor Gray

    Write-Host "" 
    Write-Host "[Environment Proxy]" -ForegroundColor Cyan
    Write-Host "HTTP_PROXY: $httpProxy" -ForegroundColor Gray
    Write-Host "HTTPS_PROXY: $httpsProxy" -ForegroundColor Gray
    Write-Host "ALL_PROXY: $allProxy" -ForegroundColor Gray

    Write-Host "" 
    Write-Host "[Effective Result]" -ForegroundColor Cyan
    if ($manualProxyOn -and $usesLocalProxyAddress -and $listening) {
        Write-Host "CURRENT_PATH: PROXY (127.0.0.1:17890)" -ForegroundColor Green
        Write-Host "[OK] System proxy is enabled and local proxy is reachable." -ForegroundColor Green
    } elseif ($manualProxyOn -and $usesLocalProxyAddress -and -not $listening) {
        Write-Host "CURRENT_PATH: BROKEN_PROXY_CONFIG" -ForegroundColor Red
        Write-Host "[WARN] System proxy points to 127.0.0.1:17890 but the port is not listening." -ForegroundColor Red
    } elseif ($pacOn) {
        Write-Host "CURRENT_PATH: PAC_SCRIPT (dynamic)" -ForegroundColor Yellow
        Write-Host "[INFO] PAC script is enabled; actual upstream proxy is decided by the script rules." -ForegroundColor Yellow
    } elseif ($autoDetectOn) {
        Write-Host "CURRENT_PATH: AUTO_DETECT (WPAD)" -ForegroundColor Yellow
        Write-Host "[INFO] Auto-detect is enabled; actual proxy depends on network WPAD response." -ForegroundColor Yellow
    } elseif ($manualProxyOn -and -not $usesLocalProxyAddress) {
        Write-Host "CURRENT_PATH: PROXY (other server)" -ForegroundColor Yellow
        Write-Host "[INFO] System proxy is enabled, but not using 127.0.0.1:17890." -ForegroundColor Yellow
    } else {
        Write-Host "CURRENT_PATH: DIRECT" -ForegroundColor Green
        Write-Host "[OK] System proxy is disabled (direct connection)." -ForegroundColor Green
    }

    if (-not $winHttpDirect) {
        Write-Host "[INFO] WinHTTP is using proxy settings (used by some CLI/services)." -ForegroundColor Yellow
    }

    exit 0
}

# Force clear mode
if ($Clear) {
    Write-Host "Mode: Force Clear Proxy" -ForegroundColor Yellow
    $listening = $false
}
elseif ($Auto) {
    Write-Host "Mode: Auto Detect" -ForegroundColor Yellow
    Write-Host "Checking if proxy service is running on ${proxyAddress}..." -ForegroundColor Gray
}

# Configure proxy based on detection result
if ($listening) {
    Write-Host "[OK] Proxy service detected on ${proxyAddress}" -ForegroundColor Green
    Write-Host "Enabling proxy configuration..." -ForegroundColor Yellow
    
    # Enable proxy
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 1
    Set-ItemProperty -Path $regPath -Name ProxyServer -Value $proxyAddress
    # Keep AutoConfigURL unchanged to avoid overriding PAC settings.
    
    Write-Host "[OK] Proxy enabled: ${proxyAddress}" -ForegroundColor Green
} else {
    Write-Host "[INFO] Proxy service not detected on ${proxyAddress}" -ForegroundColor Red
    Write-Host "Disabling proxy configuration..." -ForegroundColor Yellow
    
    # Disable proxy
    Set-ItemProperty -Path $regPath -Name ProxyEnable -Value 0
    
    if ($Clear) {
        # Clear mode: remove manual proxy address; keep AutoConfigURL unchanged.
        Remove-ItemProperty -Path $regPath -Name ProxyServer -ErrorAction SilentlyContinue
        Write-Host "[OK] Proxy disabled and ProxyServer cleared" -ForegroundColor Green
    } else {
        # Auto mode: keep ProxyServer value for quick re-enable next time.
        Write-Host "[OK] Proxy disabled (ProxyServer kept)" -ForegroundColor Green
    }
}

# Refresh Internet settings
$signature = @'
[DllImport("wininet.dll", SetLastError = true, CharSet=CharSet.Auto)]
public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);
'@

$type = Add-Type -MemberDefinition $signature -Name WinInet -Namespace InternetSettings -PassThru
$INTERNET_OPTION_SETTINGS_CHANGED = 39
$INTERNET_OPTION_REFRESH = 37
[void]$type::InternetSetOption([IntPtr]::Zero, $INTERNET_OPTION_SETTINGS_CHANGED, [IntPtr]::Zero, 0)
[void]$type::InternetSetOption([IntPtr]::Zero, $INTERNET_OPTION_REFRESH, [IntPtr]::Zero, 0)

Write-Host "`n[OK] Configuration complete! Settings refreshed." -ForegroundColor Cyan
Write-Host "Note: Some applications may need to be restarted." -ForegroundColor Gray
