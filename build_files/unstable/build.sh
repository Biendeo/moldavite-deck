#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y wireshark
chgrp wireshark /usr/sbin/dumpcap
chmod o-rx /usr/sbin/dumpcap

dnf5 install -y \
  dkms \
  kernel-devel \
  kernel-headers \
  git \
  make \
  gcc \
  patch

# git clone https://github.com/mkottman/acpi_call.git /tmp/acpi_call
# git checkout v1.1.0
# cd /tmp/acpi_call
# patch -p1 < /ctx/files/patches/acpi_call-6.17.patch
# make
# /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 \
#   /secureboot/MOK.key \
#   /secureboot/MOK.crt \
#   acpi_call.ko
# install -D -m 644 acpi_call.ko \
#   /usr/lib/modules/$(uname -r)/extra/acpi_call.ko
# depmod -a

# cd -

# dnf5 remove -y inputplumber
# dnf5 copr enable -y hhd-dev/hhd
# dnf5 install -y hhd adjustor hhd-ui
# systemctl enable hhd@$(whoami)

# cd /tmp
# wget https://raw.githubusercontent.com/OpenZotacZone/ZotacZone-Drivers/main/install_openzone_drivers.sh
# chmod +x install_openzone_drivers.sh
# echo y | sudo ./install_openzone_drivers.sh
# rm install_openzone_drivers.sh

cp /ctx/files/usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
cp /ctx/files/usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg
