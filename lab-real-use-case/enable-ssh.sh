#!/bin/bash

# Check if the file /etc/ssh/sshd_config exists
if [ ! -f /etc/ssh/sshd_config ]; then
    echo "File /etc/ssh/sshd_config does not exist."
    exit 1
fi

# Use sed to replace the value of PasswordAuthentication to yes
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Restart sshd service
sudo systemctl restart sshd

# Check if ssh-keygen is installed
if ! command -v ssh-keygen &> /dev/null; then
    echo "ssh-keygen command not found. Please install OpenSSH package."
    exit 1
fi

# Get the user's home directory
home_dir="$(eval echo ~$USER)"

# Set the default name for the key
key_name="id_rsa"

# Generate the key pair
ssh-keygen -t rsa -b 4096 -C "$key_name" -N '' -f "$home_dir/.ssh/$key_name"

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

echo "Done!"

# Use curl to get the public IP address
public_ip=$(curl  -s https://api64.ipify.org)

echo " "
echo "PUBLIC IP ADDRESS: $public_ip"
