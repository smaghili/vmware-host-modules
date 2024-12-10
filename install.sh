#!/bin/bash

# Function to check if any VPN interfaces (e.g., tun0, tun1) are active
check_vpn_active() {
    if ip a | grep -q "tun[0-9]"; then
        return 0
    else
        return 1
    fi
}

# Function to check if any common VPN processes are running
check_vpn_processes() {
    # List of common VPN processes; you can add more if needed
    vpn_processes=("openvpn" "vpnc" "wireguard" "strongswan" "anyconnect")
    for process in "${vpn_processes[@]}"; do
        if pgrep -x "$process" > /dev/null; then
            return 0
        fi
    done
    return 1
}

# Check if VPN is active or any VPN processes are running
if check_vpn_active || check_vpn_processes; then
    echo "VPN is active or the system is tunneled. Please disable VPN before running this script."
    exit 1
fi

# Get the VMware Player version
vmware_version=$(vmplayer -v | grep -oE 'Player (16|17)\.[0-9]+\.[0-9]+' | awk '{print $2}')

# Check if the version is found
if [ -z "$vmware_version" ]; then
    echo "Failed to determine the VMware Player version."
    exit 1
fi

# Extract major version
major_version=$(echo $vmware_version | cut -d. -f1)

# Download the appropriate VMware Host Modules for the detected version
wget "https://github.com/mkubecek/vmware-host-modules/archive/workstation-${vmware_version}.tar.gz"

# Extract the downloaded archive
tar -xzf "workstation-${vmware_version}.tar.gz"

# Change to the extracted directory
cd "vmware-host-modules-workstation-${vmware_version}"

# Create tar archives for vmmon and vmnet
tar -cf vmmon.tar vmmon-only
tar -cf vmnet.tar vmnet-only

# Copy the tar archives to the appropriate location
sudo cp -v vmmon.tar vmnet.tar /usr/lib/vmware/modules/source/

# Run vmware-modconfig to install the modules
sudo vmware-modconfig --console --install-all

# Cleanup: Remove the downloaded archive and extracted directory
cd ..
rm -f "workstation-${vmware_version}.tar.gz"
rm -rf "vmware-host-modules-workstation-${vmware_version}"

echo "Installation completed for VMware Player version $vmware_version"
