
<#
    .SYNOPSIS
        Valheim Server Setup

    .DESCRIPTION
        This PowerShell script is meant to install the vanilla Valheim dedicated server 
        on a Windows 10 or Windows 2016-2022 server.

    .LINK
        Github: https://github.com/CityHallin/valheim_server        
#>

#region prep

#Global variables
$valheimServerName = "valheimserver"
$valheimServerFolder = "c:\$valheimServerName"
$steamCMDFolder = "$valheimServerFolder\steamcmd"
$steamCMD = "$steamCMDFolder\steamcmd.exe"
$valheimGameFolder = "$valheimServerFolder\gamefiles"
$valheimServerStartBatchFile = "$valheimGameFolder\start_valheim_server.bat"
$startDate = Get-Date -Format "yyyy-MM-dd.HH.mm.ss"
$scheduledTaskName = "Valheim_Start"

#Start setup log file
$logFile = "c:\$($valheimServerName)_setup_log_$startDate.txt"
Start-Transcript -Path $logFile

#Verify running as administrator in PowerShell
Write-Host "`nINFO: Check if script running as administrator: " -ForegroundColor Yellow -NoNewline
$isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
If ($isAdmin -eq "True") {
    Write-Host "Running as Administrator successfully" -ForegroundColor Green
}
Else {
    Write-Host "NOT Running as Administrator" -ForegroundColor Red
    Write-Host "Please run PowerShell script as administrator" -ForegroundColor Red
    Read-Host "Press any key to close script"
    Stop-Transcript
    exit    
}

#endregion prep

#region folder_files

#Valheimserver folder_files
#Holds all Valheim related files and folders
Write-Host "`nINFO: Checking for $valheimServerFolder folder: " -ForegroundColor Yellow -NoNewline
$valheimServerFolderCheck = Test-Path -Path $valheimServerFolder
If ($valheimServerFolderCheck -eq $true) {
    Write-Host "folder already exists" -ForegroundColor cyan    
}
Else {    
    New-Item -Path $valheimServerFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
    $valheimServerFolderCheck = Test-Path -Path $valheimServerFolder
    If ($valheimServerFolderCheck -eq $true) {
        Write-Host "folder created" -ForegroundColor Green
    }
    Else {
        Write-Host "folder $valheimServerFolder could not be created" -ForegroundColor Red
        Read-Host "Press any key to close script"
        Stop-Transcript
        exit
    }
}

#Gamefiles folder
#Holds all files and folders for Valheim games files
Write-Host "`nINFO: Checking for $valheimGameFolder folder: " -ForegroundColor Yellow -NoNewline
$valheimGameFolderCheck = Test-Path -Path $valheimGameFolder
If ($valheimGameFolderCheck -eq $true) {
    Write-Host "folder already exists" -ForegroundColor cyan    
}
Else {    
    New-Item -Path $valheimGameFolder -ItemType Directory -ErrorAction SilentlyContinue | out-null
    $valheimGameFolderCheck = Test-Path -Path $valheimGameFolder
    If ($valheimGameFolderCheck -eq $true) {
        Write-Host "folder created" -ForegroundColor Green
    }
    Else {
        Write-Host "folder $valheimGameFolder could not be created" -ForegroundColor Red
        Read-Host "Press any key to close script"
        Stop-Transcript
        exit

    }
}

#SteamCMD
$steamFolderCheck = Test-Path $steamCMDFolder
Write-Host "`nINFO: Downloading SteamCMD: " -ForegroundColor Yellow -NoNewline
If ($steamFolderCheck -eq $false) {    
    Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$valheimServerFolder\steamcmd.zip" -ErrorAction SilentlyContinue   
    Expand-Archive "$valheimServerFolder\steamcmd.zip" -DestinationPath $steamCMDFolder -ErrorAction SilentlyContinue
    Remove-Item "$valheimServerFolder\steamcmd.zip" | Out-Null
}
$steamAppCheck = Test-Path $steamCMD 
If ($steamAppCheck -eq $true) {
    Write-Host "SteamCMD installed" -ForegroundColor Green
}
Else {
    Write-Host "SteamCMD install failed" -ForegroundColor Red
    Read-Host "Press any key to close script"
    Stop-Transcript
    exit
}

#endregion folder_files

#region steamcmd

#Run SteaCMD install or update
Write-Host "`nINFO: Installing Valheim Dedicated Server. This may take 5-10 minutes. Please wait..." -ForegroundColor Yellow
Write-Host "If Valheim is already installed, this will force close Valheim and perform an update." -ForegroundColor Yellow
Write-Host " "
$valheimProcessCheck = Get-Process valheim_server -ErrorAction SilentlyContinue
If (!($null -eq $valheimProcessCheck)) {
    Get-Process valheim_server | Stop-Process -ErrorAction SilentlyContinue
}
Start-Sleep 5
(cmd.exe /c $steamCMD +force_install_dir $valheimGameFolder +login anonymous +app_update 896660 validate +quit)

#Pause
Start-Sleep 2

#endregion steamcmd

#region batch_file

#Valheim batch file    
#Server name prompt
Write-Host "`nEnter the name you would like this server to be called." -ForegroundColor Yellow
Write-Host "This is what end users will see when browsing to your Valheim server." -ForegroundColor Yellow
$serverNamePrompt = Read-Host " "

#Server port prompt
Write-Host "`nEnter the port you would like this server to use (default is 2456)." -ForegroundColor Yellow
$portPrompt = Read-Host "Press the Enter key for default port [2456] or type in your own"
if ([string]::IsNullOrWhiteSpace($portPrompt)) {
    $portPrompt = "2456"
}

#Server password prompt
Write-Host "`nEnter the password you would like this server to have." -ForegroundColor Yellow
$passwordPrompt = Read-Host " "
    
#Valheim install type prompt
Do {
    Write-Host "`nWhat type of Valheim install would you like?" -ForegroundColor Yellow
    Write-Host "Enter the number choice below" -ForegroundColor Yellow
    Write-Host "  1) PC only" -ForegroundColor Magenta
    Write-Host "  2) PC and Xbox cross play" -ForegroundColor Magenta
    $installTypePrompt = Read-Host " "

    #Valheim batch file content

    switch ($installTypePrompt) {
1 {
#PC only
$startValheimServerConfig = @"
@echo off
set SteamAppId=892970
echo "Starting server PRESS CTRL-C to exit"
valheim_server -nographics -batchmode -name "$($servernameprompt)" -port $($portPrompt) -world "$($servernameprompt)" -password "$($passwordPrompt)" -public 1
"@
}
2 {
#PC and XBOX crossplay
$startValheimServerConfig = @"
@echo off
set SteamAppId=892970
echo "Starting server PRESS CTRL-C to exit"
valheim_server -nographics -batchmode -name "$($servernameprompt)" -port $($portPrompt) -world "$($servernameprompt)" -password "$($passwordPrompt)" -public 1 -crossplay
"@
}
        Default {
           Write-Host "Incorrect entry. Please choose a number for the Valheim install type" -ForegroundColor Red
        }
    }
}
until (($installTypePrompt -eq 1) -or ($installTypePrompt -eq 2))

#Build Batch file
Write-host "`nINFO: Build Valheim batch file: " -ForegroundColor Yellow -NoNewline
New-Item -Path $ValheimServerStartBatchFile -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
Add-Content -Path $ValheimServerStartBatchFile -Value $startValheimServerConfig -ErrorAction SilentlyContinue
$valheimServerStartBatchFileCheck = Test-Path $valheimServerStartBatchFile
If ($valheimServerStartBatchFileCheck -eq $true) {
    Write-host "server launch batch file created" -ForegroundColor Green
}
Else {
    Write-host "server launch batch file creation error" -ForegroundColor Red
    Read-Host "Press any key to close script"
    Stop-Transcript
    exit
}

#endregion batch_file

#region os_config

#Windows OS Firewall Rules
Write-host "`nINFO: Build Windows OS firewall rules: " -ForegroundColor Yellow -NoNewline
$firewallRuleCheck = Get-NetFirewallRule | Where-Object {($_.DisplayName -like "*Valheim*") -or ($_.DisplayName -like "*Steam*")}
If (!($null -eq $firewallRuleCheck)) {
    Write-Host "OS Firewall rules already added" -ForegroundColor Cyan
}
Else {
New-NetFirewallRule -DisplayName "Valheim_TCP" -Direction Inbound -LocalPort 2456-2457 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName "Valheim_UDP" -Direction Inbound -LocalPort 2456-2457 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName "Steam_TCP" -Direction Inbound -LocalPort 27015 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName "Steam_UDP" -Direction Inbound -LocalPort 27015 -Protocol UDP -Action Allow -ErrorAction SilentlyContinue | Out-Null
Write-Host "OS Firewall rules added" -ForegroundColor Green
}

#Disable Hibernation
Write-host "`nINFO: Disable hiberation config: " -ForegroundColor Yellow -NoNewline
$hibernationFail = $null
try {
    cmd.exe /c powercfg /hibernate off
}
Catch {
    Write-Host "Disable of hibernation failed" -ForegroundColor Red
    $hibernationFail = "yes"
}
If ($null -eq $hibernationFail) {
    Write-Host "Disable of hibernation success" -ForegroundColor Green
}

#endregion os_config

#region scheduled_task

#Scheduled task prompt
Write-host "`nA Windows scheduled task can be created to start and stop Valheim. The task" -ForegroundColor Yellow
Write-host "will be set to auto-start when the Windows machine is turned on. If you choose to enable" -ForegroundColor Yellow
Write-host "this feature, the scheduled task will be used to start and stop Valheim. If" -ForegroundColor Yellow
Write-host "this feature is not used, the $valheimServerStartBatchFile file" -ForegroundColor Yellow
Write-host "will have to be started manually." -ForegroundColor Yellow
Write-host "`nWould you like a scheduled task to be created?" -ForegroundColor Yellow
Write-host "Enter" -ForegroundColor Yellow -NoNewline
Write-host " y" -ForegroundColor Magenta -NoNewline
Write-host " for Yes or" -ForegroundColor Yellow -NoNewline
Write-host " n" -ForegroundColor Magenta -NoNewline
Write-host " for No" -ForegroundColor Yellow
$taskPrompt = Read-Host " "

If ($taskPrompt -eq "y") {

    #Set NT AUTHORITY\LOCAL SERVICE account permissions on Valheim Gamefiles folder
    #LOCAL SERVICE Account will have rights to all Valheim game files and be used to authenticate scheduled task
    $ACL = Get-Acl -Path $valheimServerFolder
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("NT AUTHORITY\LOCAL SERVICE","Modify","Allow")
    $ACL.SetAccessRule($AccessRule)
    $ACL | Set-Acl -Path $valheimServerFolder

#Build Scheduled Tasks Import XML
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
$task = Register-ScheduledTask -Xml $scheduledTask -TaskName $scheduledTaskName –Force
Write-Host "`nThe scheduled task called" -ForegroundColor Yellow -NoNewline
Write-Host " $scheduledTaskName" -ForegroundColor Magenta -NoNewline
Write-Host " was created." -ForegroundColor Yellow
Write-Host "You can manually Start and Stop this scheduled task to Start or Stop Valheim" -ForegroundColor Yellow
}

#endregion scheduled_task

#region summary_end

Write-Host "`nWould you like to Start the Valheim service from scheduled task now?" -ForegroundColor Yellow
Write-host "Enter" -ForegroundColor Yellow -NoNewline
Write-host " y" -ForegroundColor Magenta -NoNewline
Write-host " for Yes or" -ForegroundColor Yellow -NoNewline
Write-host " n" -ForegroundColor Magenta -NoNewline
Write-host " for No" -ForegroundColor Yellow
$startPrompt = Read-Host " "

If ($startPrompt -eq "y") {
    Start-ScheduledTask -TaskName $scheduledTaskName
}

#Summary
#Get server public IP
$pip = Invoke-WebRequest -Uri "https://ifconfig.me/ip" -Method Get -ErrorAction SilentlyContinue

Write-Host "`n-----Summary-----" -ForegroundColor Yellow
Write-Host "Server Name: " -ForegroundColor Yellow -NoNewline
Write-Host $serverNamePrompt -ForegroundColor Magenta
Write-Host "Server Password: " -ForegroundColor Yellow -NoNewline
Write-Host $passwordPrompt -ForegroundColor Magenta
Write-Host "Server Public IP and Port: " -ForegroundColor Yellow -NoNewline
Write-Host $pip.Content -ForegroundColor Magenta -NoNewline
Write-Host ":" -ForegroundColor Magenta -NoNewline
Write-Host $portPrompt -ForegroundColor Magenta
Write-Host "Game Files Location: " -ForegroundColor Yellow -NoNewline
Write-Host $valheimGameFolder -ForegroundColor Magenta
Write-Host "Server Launch Batch File: " -ForegroundColor Yellow -NoNewline
Write-Host $valheimServerStartBatchFile -ForegroundColor Magenta

#Stop log
Write-Host " "
Stop-Transcript
Read-Host "Press any key to close script"

#endregion summary_end
