#!/bin/bash

# Script to install disablesnapro hook and install files to initcpio directories
# Run this from the folder containing disablesnapro-hook and disablesnapro-install files

set -e  # Exit on any error

# Check if required files exist in current directory
if [[ ! -f "disablesnapro-hook" ]]; then
    echo "Error: disablesnapro-hook not found in current directory"
    exit 1
fi

if [[ ! -f "disablesnapro-install" ]]; then
    echo "Error: disablesnapro-install not found in current directory"
    exit 1
fi

# Create target directories if they don't exist
sudo mkdir -p /etc/initcpio/hooks
sudo mkdir -p /etc/initcpio/install

echo "Installing disablesnapro hook and install files..."

# 1. Copy disablesnapro-hook to /etc/initcpio/hooks/ as executable
sudo cp disablesnapro-hook /etc/initcpio/hooks/disablesnapro
sudo chmod +x /etc/initcpio/hooks/disablesnapro

# 2. Copy disablesnapro-install to /etc/initcpio/install/ as executable  
sudo cp disablesnapro-install /etc/initcpio/install/disablesnapro
sudo chmod +x /etc/initcpio/install/disablesnapro

echo "Installation complete!"
echo "Don't forget to run 'sudo mkinitcpio -P' to regenerate initramfs after installation."
