#!/bin/bash

# Use curl to get the public IP address
public_ip=$(curl  -s https://api64.ipify.org)

echo " "
echo "PUBLIC IP ADDRESS: $public_ip"
