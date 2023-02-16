[CmdletBinding()]
param(
    $AdapterName = "DevOpsifyMe DNS",
    $TaskName = "DevOpsifyMe DNS - Reload Configuration"
)

Remove-VMSwitch -Name $AdapterName -Force
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false