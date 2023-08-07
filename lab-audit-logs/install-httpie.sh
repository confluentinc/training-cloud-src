#!/bin/bash

[ `whoami` = root ] || exec su -c $0 root

# Download the GPG key and add it to the keyring
curl -SsL https://packages.httpie.io/deb/KEY.gpg | sudo gpg --dearmor -o /usr/share/keyrings/httpie.gpg

# Add the HTTPie repository to the sources list
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/httpie.gpg] https://packages.httpie.io/deb ./" > /etc/apt/sources.list.d/httpie.list

# Update the package lists
sudo apt update

# Install HTTPie
sudo apt install httpie