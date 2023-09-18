#!/usr/bin/env bash

echo "[Installing kube-autocomplete]"

sudo apt-get install bash-completion

# source bash-completion to .bashrc
echo 'source /usr/share/bash-completion/bash_completion' >> ~/.bashrc

# now append kuber autocomplete
echo 'source <(kubectl completion bash)' >> ~/.bashrc

# Source bashrc
source ~/.bashrc
