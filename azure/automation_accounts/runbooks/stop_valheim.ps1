
<#
    .SYNOPSIS
        Stop Valheim Scheduled Task

    .DESCRIPTION
        This PowerShell script is meant to be run from an Azure Automation Account
        to stop a Valheim VM's Valheim scheduled task. 

    .LINK
        Github: https://github.com/CityHallin/valheim_server        
#>

#Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

#Connect to Azure with system-assigned managed ID
Write-Output "INFO: Logging in with Automation Account System-Managed ID"
$context = (Connect-AzAccount -Identity).Context

#Set and store login context
If ($null -eq $($context.Subscription.name)) {
    throw (Write-Error -Message "Automation Account System-Managed ID could not log into Azure. Runbook stopped")
    exit
}
Else {
    Write-Output "INFO: Logged in successfully. Subscription=$($context.Subscription.name)"
}

#Stop Valheim scheduled task
Invoke-AzVMRunCommand -ResourceGroupName "Valheim-dev" -VMName "Valheim-dev" -CommandId 'RunPowerShellScript' -ScriptString "Stop-ScheduledTask -TaskName Valheim_Start"
