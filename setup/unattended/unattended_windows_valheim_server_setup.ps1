
<#
    .SYNOPSIS
        Unattended Valheim Dedicated Server Setup

    .DESCRIPTION
        This PowerShell script is meant to install the vanilla Valheim dedicated server 
        on a Windows 10 or Windows 2016-2022 server without user interaction. Not meant 
        to be used by end users, but rather automation resources. Valheim is started 
        and stopped by starting or stopping a scheduled task. Add the -crosssplay switch
        to the batch file section if you want to enable croassplay. 

        Folder locations:
        - Valheim game and batch files = c:\valheimserver\gamefiles
        - Logs = c:\valheimserver\gamefiles\logs
        - World folder = c:\valheimserver\gamefiles\world        

    .LINK
        Github: https://github.com/CityHallin/valheim_server        
#>

#Change $serverName and $serverPassword variables below to what you want
$serverName = "{{ ENTER VALHEIM SERVER NAME HERE }}"
$serverPassword = "{{ ENTER VALHEIM SERVER PASSWORD SECRET HERE }}"

#Global variables
$port = "2456"
$valheimServerName = "valheimserver"
$valheimServerFolder = "c:\$valheimServerName"
$steamCMDFolder = "$valheimServerFolder\steamcmd"
$steamCMD = "$steamCMDFolder\steamcmd.exe"
$valheimGameFolder = "$valheimServerFolder\gamefiles"
$valheimServerStartBatchFile = "$valheimGameFolder\start_valheim_server.bat"
$startDate = Get-Date -Format "yyyy-MM-dd.HH.mm.ss"
$scheduledTaskName = "Valheim_Start"

#Start setup log file
Start-Transcript -Path "c:\$($valheimServerName)_setup_log_$startDate.txt"

#Valheimserver folder
Write-Host "`nCreate Valheimserver folder"
New-Item -Path $valheimServerFolder -ItemType Directory

#Gamefiles folder
Write-Host "`nCreate Gamefiles folder"
New-Item -Path $valheimGameFolder -ItemType Directory

#Set NT AUTHORITY\LOCAL SERVICE account permissions on Valheim Gamefiles folder
#LOCAL SERVICE Account will have rights to all Valheim game files and be used to authenticate scheduled task
Write-Host "`nGive Local Service access to Valheimserver folder"
$ACL = Get-Acl -Path $valheimServerFolder
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\LOCAL SERVICE","Modify","Allow")
$ACL.SetAccessRule($AccessRule)
$ACL | Set-Acl -Path $valheimServerFolder

#SteamCMD
Write-Host "`nDownload SteamCMD"
Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$valheimServerFolder\steamcmd.zip" 
Expand-Archive "$valheimServerFolder\steamcmd.zip" -DestinationPath $steamCMDFolder
Remove-Item "$valheimServerFolder\steamcmd.zip"

#Run SteamCMD install or update
Write-Host "`nInstall Valheim Dedicated Server"
cmd.exe /c $steamCMD +force_install_dir $valheimGameFolder +login anonymous +app_update 896660 validate +quit
Start-Sleep 2

#Batch file content
Write-Host "`nCreate server launch batch file"
$startValheimServerConfig = @"
@echo off
set SteamAppId=892970
echo "Starting server PRESS CTRL-C to exit"
valheim_server -logFile "$($valheimGameFolder)\logs\log.txt" -nographics -batchmode -name "$($serverName)" -port $($port) -world "$($serverName)" -password "$($serverPassword)" -savedir "$($valheimGameFolder)\world" -public 1
"@

#Build batch file
New-Item -Path $ValheimServerStartBatchFile -ItemType File -Force
Add-Content -Path $ValheimServerStartBatchFile -Value $startValheimServerConfig

#Windows OS Firewall Rules
Write-Host "`nAdd OS firewall rules"
New-NetFirewallRule -DisplayName "Valheim_TCP" -Direction Inbound -LocalPort 2456-2457 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Valheim_UDP" -Direction Inbound -LocalPort 2456-2457 -Protocol UDP -Action Allow
New-NetFirewallRule -DisplayName "Steam_TCP" -Direction Inbound -LocalPort 27015 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Steam_UDP" -Direction Inbound -LocalPort 27015 -Protocol UDP -Action Allow

#Disable Hibernation
Write-Host "`nDisable hibernate"
cmd.exe /c powercfg /hibernate off

#Build Scheduled Tasks Import XML
Write-Host "`nBuild scheduled task"
$scheduledTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2023-01-28T07:50:46.7130712</Date>
    <Author>$env:COMPUTERNAME\$env:USERNAME</Author>
    <URI>\$scheduledTaskName</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
      <Delay>PT1M</Delay>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-19</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\valheimserver\gamefiles\start_valheim_server.bat</Command>
      <WorkingDirectory>C:\valheimserver\gamefiles</WorkingDirectory>
    </Exec>
  </Actions>
</Task>
"@

#Import Scheduled task
Register-ScheduledTask -Xml $scheduledTask -TaskName $scheduledTaskName -Force

#Start scheduled task
Write-Host "`nStarting Valheim scheduled task"
Start-sleep 30
Start-ScheduledTask -TaskName $scheduledTaskName

#Stop log
Stop-Transcript
