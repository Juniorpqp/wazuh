# Wazuh Upgrade Script

## Overview
This script automates the upgrade process for Wazuh components, including the Wazuh Indexer, Manager, and Dashboard. It checks installed versions, compares them with the latest available versions, and performs the upgrade if necessary.

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

Review the current and available Wazuh versions.
Confirm the upgrade process when prompted.
The script will automatically upgrade all necessary components and restart services.

## Post-Upgrade
After the upgrade is completed, the script will display the installed versions of Wazuh components to confirm the successful update.

## Troubleshooting
```
- If the script fails, check the logs for error messages.
- Ensure you have a working internet connection to fetch package updates.
- Verify that your Wazuh repository is correctly configured.
```

## License
```
This project is licensed under the MIT License.
```

## Contribution
```
Feel free to contribute to this project by submitting issues and pull requests on GitHub.
```

---
🎉 Enjoy a seamless Wazuh upgrade experience!

