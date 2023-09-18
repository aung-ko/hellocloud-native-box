#!/usr/bin/env bash

echo "[Installing bash-it]"

# Clone Bash-it repository to ~/.bash_it
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it

# Run the Bash-it installation script
~/.bash_it/install.sh

# Source the Bash-it initialization script to load Bash-it
source ~/.bashrc
