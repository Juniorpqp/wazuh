# Wazuh Upgrade Script

## Overview
This script automates the upgrade process for Wazuh components, including the Wazuh Indexer, Manager, and Dashboard. It checks installed versions, compares them with the latest available versions, and performs the upgrade if necessary, with logging, safety prompts, and version control.

## Features
- Checks the currently installed Wazuh versions
- Compares installed versions with available versions in the repository
- Prompts the user for confirmation before upgrading
- Prepares the Wazuh cluster for upgrade
- Stops necessary services before installation
- Upgrades Wazuh Indexer, Manager, and Dashboard
- Configures Filebeat for compatibility
- Restarts all services after the upgrade
- Disables the Wazuh repository after the process
- **Creates a timestamped log file** for each upgrade session
- **Includes a safeguard function** to hold/unhold Wazuh packages to prevent accidental upgrades
- **Fixes broken service checks** and improves error visibility

## Prerequisites
```
- A Debian-based Linux distribution (Ubuntu, Debian, etc.)
- Wazuh components already installed
- sudo/root privileges
- An active Wazuh repository in /etc/apt/sources.list.d/wazuh.list
```

## Installation
```
chmod +x upgrade_wazuh.sh
```

## Usage
```
./upgrade_wazuh.sh
```

Enter the required details when prompted:
```
- Wazuh Indexer IP
- Wazuh Admin Username
- Wazuh Admin Password
```

The script will:
- Display current and available Wazuh versions
- Ask whether to unlock held packages
- Perform the upgrade process if confirmed

📝 **A detailed log will be saved in the current directory**, e.g.:
```
upgrade-log-2025-05-22-1534.txt
```

## Post-Upgrade
After the upgrade, the script will display the installed versions of Wazuh components and confirm that the packages were successfully updated.

## Troubleshooting
```
- If the script fails, check the generated log file for error messages.
- Please ensure you have a working internet connection to fetch package updates.
- Verify that your Wazuh repository is correctly configured.
```

## Notes
- [ ] **Check Filebeat template compatibility**: If Wazuh releases a new Filebeat template version, update the link or logic in the script to match.

📖 Official docs:  
https://documentation.wazuh.com/current/upgrade-guide/upgrading-central-components.html

---
🎉 Enjoy a safer and more traceable Wazuh upgrade experience!
