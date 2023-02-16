[CmdletBinding()]
param(
    $AdapterName = "DevOpsifyMe DNS",
    $TaskName = "DevOpsifyMe DNS - Reload Configuration",
    $LocalAddress = "10.22.33.1"
)

$ErrorActionPreference = 'Stop'

# Create vSwitch
(Get-VMSwitch $AdapterName -ErrorAction SilentlyContinue) `
    ?? (New-VMSwitch -Name $AdapterName -SwitchType Internal)

$adapter = Get-NetAdapter -Name "vEthernet ($AdapterName)" -IncludeHidden
if('Disabled' -eq $adapter.Status)
{
    Write-Error "$($adapter.Name) seems to be $($adapter.Status), is that correct? Aborting."
}

# Configure Adapter
(Get-NetIpAddress -IPAddress $LocalAddress -ErrorAction SilentlyContinue) `
    ?? (New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $LocalAddress)
Set-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $LocalAddress -PrefixLength 24
Set-NetIPInterface -InterfaceIndex $adapter.InterfaceIndex -InterfaceMetric 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ($LocalAddress)

# Register Configuration Reload Task
[Xml]$taskDefinition = Get-Content .\reload-task.xml
$taskDefinition.Task.Actions.Exec.WorkingDirectory = Get-Location

(Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) `
    ?? (Register-ScheduledTask -TaskName $TaskName -Xml $taskDefinition.InnerXml)