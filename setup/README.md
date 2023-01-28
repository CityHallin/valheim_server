## Setup Valheim Dedicated Server on Windows

This script will assist in the setup of a Valheim dedicated server on a Windows 10 or Windows 2016-2022 server system using Steam. The script will do the following:

- Create an install log
- Check if PowerShell is running as administrator (required)
- Build needed folders to hold all the Valheim files
- Install SteamCMD and Valheim Dedicated Server. Depending on your internet connection this could take 5-10 minutes so please wait for this to complete
- Will prompt you for the following info:
    - Server Name
    - Server Port (will default to 2456 unless you type in your own)
    - Server Password
    - Install Type (PC only or Crossplay)
- Build the Valheim launch batch file
- Create Windows OS firewall rules for Valheim and Steam
- Disable hibernation power config on Windows
- Prompt if you wish to build a auto-start scheduled task for Valheim. If this is chosen, Valheim can be started and stopped from the scheduled task. The scheduled task will auto-start Valheim any time the Windows machine is rebooted. 
- Prompt if you wish to have the script start the Valheim scheduled task at that moment
- Give a summary of the Valheim install

## Requirements

- Currently only works with Windows 10 and Windows Server 2016-2022
- This script is meant for new installs of Valheim Dedicated Server
- This PowerShell script must be run as Administrator
- The user running this script must be an administrator on the Windows machine
- This is a vanilla install of Valheim Dedicated Server from Steam. No mods are used for this install

## Post Tasks

Below are a list of things you will still need to do that this script cannot help with:

- Set up port forwarding on your router to allow gamers to connect with your server. This script only adds firewall rules on your Windows machine
- You will be responsible for backing up your Valheim world and saves


