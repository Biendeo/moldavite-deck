#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y wireshark
chgrp wireshark /usr/sbin/dumpcap
chmod o-rx /usr/sbin/dumpcap

dnf5 copr enable hhd-dev/hhd
dnf5 install hhd adjustor hhd-ui
systemctl enable hhd@$(whoami)

# cd /tmp
# wget https://raw.githubusercontent.com/OpenZotacZone/ZotacZone-Drivers/main/install_openzone_drivers.sh
# chmod +x install_openzone_drivers.sh
# echo y | sudo ./install_openzone_drivers.sh
# rm install_openzone_drivers.sh