#!/bin/bash

LOG_FILE="upgrade-log-$(date +%F-%H%M).txt"
exec > >(tee -a "$LOG_FILE") 2>&1

if tput cols &>/dev/null; then
    TERM_WIDTH=$(tput cols)
else
    TERM_WIDTH=80
fi

LOGO=(
" __       __   ______   ________  __    __  __    __ "
"|  \\  _  |  \\ /      \\ |        \\|  \\  |  \\|  \\  |  \\"
"| \$ / \\ | \$|  \$\$| \\\\\$| \$  | \$| \$  | \$"
"| \$/  \\| \$| \$__| \$    /  \$ | \$  | \$| \$__| \$"
"| \$  \$\$| \$| \$    \$   /  \$  | \$  | \$| \$    \$"
"| \$ \$\$| \$\$\$| \$\$\$  /  \$   | \$  | \$| \$\$\$ "
"| \$\$\$  \\\$| \$  | \$ /  \$___ | \$\$__/ \$| \$  | \$"
"| \$\$\$    \\\$| \$  | \$|  \$    \\ \\\$    \$| \$  | \$"
" \\\$      \\\$ \\\$   \\\$ \\\$\$\$  \\\$  \\\$   \\\$"
)
TAGLINE="Wazuh: Security Monitoring and SIEM"
print_centered() {
    local text="$1"
    printf "%*s\n" $(( (${#text} + TERM_WIDTH) / 2)) "$text"
}

echo ""
for line in "${LOGO[@]}"; do
    print_centered "$line"
done
echo ""
print_centered "$TAGLINE"
echo ""


echo "📦  Packages in hold:"
apt-mark showhold | grep -E 'wazuh-indexer|wazuh-dashboard|wazuh-manager|filebeat'
echo ""

prompt_unlock_packages() {
    read -rp "🔓 Do you want to unlock Wazuh packages for upgrade? (yes/no): " answer
    case "$answer" in
        [Yy][Ee][Ss]|[Yy])
            echo "✅ Unlocking Wazuh components..."
            apt-mark unhold wazuh-indexer wazuh-dashboard wazuh-manager filebeat
            echo ""
            echo "📦  Packages no longer on hold:"
            apt-mark showhold | grep -E 'wazuh-indexer|wazuh-dashboard|wazuh-manager|filebeat' || echo "None"
            echo ""
            ;;
        [Nn][Oo]|[Nn])
            echo "❌ Aborting script."
            exit 1
            ;;
        *)
            echo "⚠️  Invalid input. Please enter yes or no."
            prompt_unlock_packages  # Recurse to ask again
            ;;
    esac
}

prompt_unlock_packages


apt-get install gnupg apt-transport-https
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

# Function to get the installed version of a package
get_installed_version() {
    dpkg-query -W -f='${Version}' "$1" 2>/dev/null || echo "Not Installed"
}

# Function to get the available version of a package from the repository
get_available_version() {
    apt-cache policy "$1" | awk '/Candidate:/ {print $2}' || echo "Unknown"
}

# Prompt for sensitive details (hidden input for password)
read -p "Enter Wazuh Indexer IP (default: 0.0.0.0): " WAZUH_IP
WAZUH_IP=${WAZUH_IP:-0.0.0.0}

read -p "Enter Wazuh Admin Username: " WAZUH_USER
while [[ -z "$WAZUH_USER" ]]; do
    echo "Username cannot be empty!"
    read -p "Enter Wazuh Admin Username: " WAZUH_USER
done

read -s -p "Enter Wazuh Admin Password: " WAZUH_PASS
echo ""
while [[ -z "$WAZUH_PASS" ]]; do
    echo "Password cannot be empty!"
    read -s -p "Enter Wazuh Admin Password: " WAZUH_PASS
    echo ""
done

# Enable Wazuh repository if file exists
if [[ -f /etc/apt/sources.list.d/wazuh.list ]]; then
    echo "🔄 Enabling Wazuh repository..."
    sudo sed -i 's/^# \(deb.*\)/\1  # Comment moved/' /etc/apt/sources.list.d/wazuh.list
else
    echo "⚠️ Wazuh repository file not found! Skipping repository enabling..."
fi

# Update package list
echo "🔄 Updating package list..."
sudo apt update -y

# Get current and available versions
indexer_installed=$(get_installed_version wazuh-indexer)
manager_installed=$(get_installed_version wazuh-manager)
dashboard_installed=$(get_installed_version wazuh-dashboard)

indexer_available=$(get_available_version wazuh-indexer)
manager_available=$(get_available_version wazuh-manager)
dashboard_available=$(get_available_version wazuh-dashboard)

echo "📌 Current Installed Versions:"
echo "   - Wazuh Indexer:   $indexer_installed"
echo "   - Wazuh Manager:   $manager_installed"
echo "   - Wazuh Dashboard: $dashboard_installed"
echo " "
echo "📌 Available Versions in Repository:"
echo "   - Wazuh Indexer:   $indexer_available"
echo "   - Wazuh Manager:   $manager_available"
echo "   - Wazuh Dashboard: $dashboard_available"

# Check if upgrade is needed
if [[ "$indexer_installed" == "$indexer_available" && "$manager_installed" == "$manager_available" && "$dashboard_installed" == "$dashboard_available" ]]; then
    echo "✅ You are already running the latest Wazuh version. No upgrade needed."

    if [[ -f /etc/apt/sources.list.d/wazuh.list ]]; then
        echo "🔄 Disabling Wazuh repository..."
        sudo sed -i 's/^\(deb.*\)  # Comment moved/# \1/' /etc/apt/sources.list.d/wazuh.list
    fi
    exit 0
fi

# Show version differences
echo "🔍 The following components have newer versions available:"
[[ "$indexer_installed" != "$indexer_available" ]] && echo "   - Wazuh Indexer: $indexer_installed ➝ $indexer_available"
[[ "$manager_installed" != "$manager_available" ]] && echo "   - Wazuh Manager: $manager_installed ➝ $manager_available"
[[ "$dashboard_installed" != "$dashboard_available" ]] && echo "   - Wazuh Dashboard: $dashboard_installed ➝ $dashboard_available"

# Prompt user for confirmation
read -p "⚠️ Do you want to proceed with the upgrade? (yes/no): " confirm
confirm=${confirm,,}  # Convert to lowercase
if [[ "$confirm" != "yes" ]]; then
    echo "❌ Upgrade cancelled."

    if [[ -f /etc/apt/sources.list.d/wazuh.list ]]; then
        echo "🔄 Disabling Wazuh repository..."
        sudo sed -i 's/^\(deb.*\)  # Comment moved/# \1/' /etc/apt/sources.list.d/wazuh.list
    fi
    exit 0
fi

echo "🚀 Starting upgrade process..."

echo "🛑 Stopping Filebeat and Dashboard..."
systemctl stop filebeat
systemctl stop wazuh-dashboard

# Prepare cluster for upgrade
echo "🔄 Preparing cluster..."
curl -X PUT "https://$WAZUH_IP:9200/_cluster/settings" -u $WAZUH_USER:$WAZUH_PASS -k -H "Content-Type: application/json" -d '
{
   "persistent": {
      "cluster.routing.allocation.enable": "primaries"
   }
}'

curl -X POST "https://$WAZUH_IP:9200/_flush" -u $WAZUH_USER:$WAZUH_PASS -k


echo "🛑 Stopping Wazuh services..."
systemctl stop wazuh-manager
curl -k -u $WAZUH_USER:$WAZUH_PASS https://$WAZUH_IP:9200/_cat/nodes?v


systemctl stop wazuh-indexer

echo "📦 Installing new Wazuh Indexer version..."
apt-get install -y wazuh-indexer

echo "✅ Restarting Wazuh Indexer..."
systemctl daemon-reload
systemctl enable wazuh-indexer
systemctl start wazuh-indexer


# Checking Indexer
curl -k -u $WAZUH_USER:$WAZUH_PASS https://$WAZUH_IP:9200/_cat/nodes?v

echo "🔄 Re-enable shard allocation"

curl -X PUT "https://$WAZUH_IP:9200/_cluster/settings" \
-u $WAZUH_USER:$WAZUH_PASS -k -H "Content-Type: application/json" -d '
{
   "persistent": {
      "cluster.routing.allocation.enable": "all"
   }
}
'
curl -k -u $WAZUH_USER:$WAZUH_PASS https://$WAZUH_IP:9200/_cat/nodes?v

systemctl start wazuh-manager


# Upgrade Wazuh Manager
echo "🔄 Upgrading Wazuh Manager..."
apt-get install -y wazuh-manager

# Upgrade Filebeat
echo "🔄 Configuring Filebeat..."
curl -s https://packages.wazuh.com/4.x/filebeat/wazuh-filebeat-0.4.tar.gz | sudo tar -xvz -C /usr/share/filebeat/module
curl -so /etc/filebeat/wazuh-template.json https://raw.githubusercontent.com/wazuh/wazuh/v4.12.0/extensions/elasticsearch/7.x/wazuh-template.json
chmod go+r /etc/filebeat/wazuh-template.json

systemctl daemon-reload
systemctl enable filebeat
systemctl start filebeat

filebeat setup --pipelines
filebeat setup --index-management -E output.logstash.enabled=false

# Upgrade Wazuh Dashboard
echo "🔄 Upgrading Wazuh Dashboard..."
apt-get install -y wazuh-dashboard
systemctl daemon-reload
systemctl enable wazuh-dashboard
systemctl start wazuh-dashboard


# Show final versions
echo "✅ Upgrade complete! Installed versions:"
apt list --installed wazuh-indexer
apt list --installed wazuh-manager
apt list --installed wazuh-dashboard

# Disable Wazuh repository
#if [[ -f /etc/apt/sources.list.d/wazuh.list ]]; then
#    echo "🔄 Disabling Wazuh repository..."
#    sudo sed -i 's/^\(deb.*\)  # Comment moved/# \1/' /etc/apt/sources.list.d/wazuh.list
#fi

# Prevent Upgrade Wazuh components
echo "🛑 Prevent Upgrade Wazuh components"
apt-mark hold wazuh-indexer wazuh-dashboard wazuh-manager filebeat
echo ""
echo "📦  Packages in hold:"
apt-mark showhold | grep -E 'wazuh-indexer|wazuh-dashboard|wazuh-manager|filebeat'
echo ""

echo "Services status:"
systemctl status filebeat wazuh-indexer wazuh-dashboard wazuh-manager | grep -B 2 Active
echo ""


echo "🎉 Wazuh upgrade process finished!"
echo "📝 Log saved to: $(pwd)/$LOG_FILE"
