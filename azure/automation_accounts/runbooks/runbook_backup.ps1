
<#
    .SYNOPSIS
    Backup Valheim Server

    .DESCRIPTION
    This PowerShell script is meant to run inside Azure Function Apps or 
    Automation Account that will trigger a backup of the Valheim world
    to Azure Storage. 

    .LINK
    Github: https://github.com/CityHallin/valheim_server
           
#>

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect to Azure with system-assigned managed ID
Write-Output "INFO: Logging in with System-Managed ID"
$context = (Connect-AzAccount -Identity).Context

# Set and store login context
If ($null -eq $($context.Subscription.name)) {
    throw (Write-Error -Message "System-Managed ID could not log into Azure. Stopped")
    exit
}
Else {
    Write-Output "INFO: Logged in successfully. Subscription $($context.Subscription.name)"
}

#Import-Modules
Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Compute

#Get VM Info
$vmInfo = Get-AzResource | Where-Object {($_.ResourceType -eq "Microsoft.Compute/virtualMachines") -and ($_.Name -like "*valheim*")}

#Run command on VM
$timeStamp = get-date -Format "yyyy.MM.dd.HH.mm.ss"
$url = "https://raw.githubusercontent.com/CityHallin/valheim_server/main/azure/automation_accounts/runbooks/backup.ps1"
#Invoke-AzVMRunCommand -ResourceGroupName $($vmInfo.ResourceGroupName) -VMName $($vmInfo.Name) -CommandId 'RunPowerShellScript' -ScriptPath $url
Set-AzVMRunCommand -ResourceGroupName $($vmInfo.ResourceGroupName) -VMName $($vmInfo.Name) -Location $($vmInfo.Location) -RunCommandName "backup.$timeStamp" -SourceScriptUri $url
Write-Output "INFO: Kicked off backup called: backup.$timeStamp"
