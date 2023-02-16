[CmdletBinding()]
param(
    $AdapterName = "DevOpsifyMe DNS"
)

$ErrorActionPreference = 'Stop'

# Find our artificial adapter IP address, so the container can bind to it
$dnsAdapter = Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object { $_.InterfaceAlias -Like "*($AdapterName)*" } `
    | Select-Object -First 1

if($null -eq $dnsAdapter)
{
    Write-Warning "$AdapterName adapter not found, did you register it?"
    Write-Warning "Binding to 127.0.0.1:53/udp for testing, no traffic is redirected..."
    Write-Warning "... use 'nslookup google.com 127.0.0.1' to query CoreDNS manually."
}

# Get Name Servers from the first connected adapter, sorted by Metric
$nextAdapter = Get-NetAdapter `
    | Where-Object { $_.Status -eq 'Up' } `
    | Get-NetIPInterface -AddressFamily IPv4 `
    | Sort-Object -Property InterfaceMetric `
    | ForEach-Object { Get-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex } `
    | Where-Object { $_.ServerAddresses.Count -gt 0 } `
    | Where-Object { $_.InterfaceAlias -NotLike "*($AdapterName)*" } `
    | Select-Object -First 1

Write-Warning "Using NS $($nextAdapter.ServerAddresses) from $($nextAdapter.InterfaceAlias) adapter"

# Set variables for the CoreDNS
$env:HOST_BIND = $dnsAdapter.IPAddress
$env:NS_1 = $nextAdapter.ServerAddresses | Select-Object -First 1
$env:NS_2 = $nextAdapter.ServerAddresses | Select-Object -First 1 -Skip 1
$env:NS_3 = $nextAdapter.ServerAddresses | Select-Object -First 1 -Skip 2
$env:NS_2 ??= $env:NS_1
$env:NS_3 ??= $env:NS_2

docker compose up -d