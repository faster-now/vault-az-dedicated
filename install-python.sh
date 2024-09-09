#!/bin/bash

sudo apt-get update
sudo apt-get install -y python3-pip
sudo apt-get install -y pipx
pipx ensurepath
pip install -t /home/azureuser/.local/share/pipx/shared/lib/python3.12/site-packages hvac
#sudo pip3 install --upgrade pip --break-system-packages python3 already installed on newer Ubuntu 24.04 LTS version