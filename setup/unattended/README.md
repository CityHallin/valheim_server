
## Unattended Setup Valheim Dedicated Server on Windows

These scripts will install Valheim dedicated server on a Windows 10 or Windows 2016-2022 server system using Steam in an unattended manner. These scripts are meant to be run by automation and not by end users. The two versions of the script give the opportunity to install vanilla Valheim Dedicated Server or Valheim Dedicated Server with some mods.

## Before running this script

- Update the variable **$serverName** with the server name you want this system to have. This will be what end users see when connecting to your Valheim server
- Update the variable **$serverPassword** with the password you will require end users to type in to connect to your server. If possible, I recommend storing your password in a CICD pipeline vault and having a secrets variable reference it. This way if you publish this code to a repo, your server password will not be visible to all viewers.
- Make sure your Windows OS firewall is turned on as this script will add the needed Windows OS firewall rules 

## What this script will do

- Create an install log
- Build needed folders to hold all the Valheim files
- Install SteamCMD and Valheim Dedicated Server. 
- Build the Valheim launch batch file with your server name, server password, default port 2456, and by default no cross play. If you wish this to be used for cross play add the "- crossplay" switch to the batch file creation section
- Create Windows OS firewall rules for Valheim and Steam
- Disable hibernation power config on Windows
- Build a scheduled task for Valheim. You can start and stop Valheim from the scheduled task. The scheduled task will auto-start Valheim any time the Windows machine is rebooted. 
- The mod version of the script will install mods:
    - [Valheim Plus](https://www.nexusmods.com/valheim/mods/4)
    - [Jotunn](https://www.nexusmods.com/valheim/mods/1138) (requirement for other mods)
    - [Valheim Raft](https://www.nexusmods.com/valheim/mods/1136)
- Add Azure PowerShell modules

## Requirements

- Currently only works with Windows 10 and Windows Server 2016-2022
- This script is meant for new deployments of Valheim Dedicated Server
- The automation running this script must have administrative rights on the Windows machine

## Post Tasks

Below are a list of things you will still need to do that this script cannot help with:

- Set up port forwarding on your router to allow gamers to connect with your server. This script only adds firewall rules on your Windows machine
- You will be responsible for backing up your Valheim world and saves


