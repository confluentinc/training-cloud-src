#!/bin/sh

# Install Bash completion 
apt-get install bash-completion

# Set the confluent completion code for Bash to a file that’s sourced on login
confluent completion bash > /etc/bash_completion.d/confluent

# Load the confluent completion code for Bash into the current shell 
source /etc/bash_completion.d/confluent

# Add the source command to ~/.bashrc to enable completions for new terminals
echo "source /etc/bash_completion.d/confluent" >> /home/training/.bashrc