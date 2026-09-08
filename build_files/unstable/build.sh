#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y wireshark
chgrp wireshark /usr/sbin/dumpcap
chmod o-rx /usr/sbin/dumpcap

dnf5 install -y \
  gcc \
  make \
  wget

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

### OpenZONE drivers for the Zotac Zone (ZGC-G1A1W)
# Build inline against the image's own kernel. `uname -r` inside podman build is the
# CI host kernel, so target /lib/modules/<ver>/build explicitly instead of $(uname -r).
KERNEL_VERSION=$(ls /usr/lib/modules/ | grep -v 'debug' | sort -V | tail -n 1)

dnf5 install -y "kernel-devel-${KERNEL_VERSION}"

BUILD_DIR="/tmp/zotac_zone_build"
# /usr/lib (not /usr/local): /usr/local is absent/non-dir in this image, mkdir -p trips on it
DRIVER_INSTALL_DIR="/usr/lib/zotac-zone"
mkdir -p "$BUILD_DIR" "$DRIVER_INSTALL_DIR"
cd "$BUILD_DIR"

OPENZONE_RAW="https://raw.githubusercontent.com/OpenZotacZone/ZotacZone-Drivers/refs/heads/main"
for f in \
    "zotac-zone-hid-core.c" \
    "zotac-zone-hid-rgb.c" \
    "zotac-zone-hid-input.c" \
    "zotac-zone-hid-config.c" \
    "zotac-zone.h"
do
    wget -q "${OPENZONE_RAW}/driver/hid/${f}"
done

for f in \
    "zotac-zone-platform.c" \
    "firmware_attributes_class.h" \
    "firmware_attributes_class.c"
do
    wget -q "${OPENZONE_RAW}/driver/platform/${f}"
done

cat > Makefile << 'EOF'
obj-m += zotac-zone-hid.o
zotac-zone-hid-y := zotac-zone-hid-core.o zotac-zone-hid-rgb.o zotac-zone-hid-input.o zotac-zone-hid-config.o
obj-m += firmware_attributes_class.o
obj-m += zotac-zone-platform.o
all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
EOF

make -C "/usr/lib/modules/${KERNEL_VERSION}/build" M="$(pwd)" modules
cp *.ko "$DRIVER_INSTALL_DIR/"

### Sign OpenZONE modules for Secure Boot (MOK)
if [ -f /secureboot/MOK.key ] && [ -f /secureboot/MOK.crt ]; then
  for ko in "${DRIVER_INSTALL_DIR}"/*.ko; do
    [ -e "$ko" ] || continue
    "/usr/src/kernels/${KERNEL_VERSION}/scripts/sign-file" sha256 \
      /secureboot/MOK.key /secureboot/MOK.crt "$ko"
  done
else
  echo "WARNING: MOK key/cert not found; OpenZONE modules left unsigned."
fi

cat > /usr/lib/systemd/system/zotac-zone-drivers.service << EOF
[Unit]
Description=Zotac Zone HID & Platform Drivers (OpenZONE)
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/modprobe led-class-multicolor
ExecStart=/usr/sbin/modprobe platform_profile
ExecStart=/usr/sbin/insmod ${DRIVER_INSTALL_DIR}/firmware_attributes_class.ko
ExecStart=/usr/sbin/insmod ${DRIVER_INSTALL_DIR}/zotac-zone-platform.ko
ExecStart=/usr/sbin/insmod ${DRIVER_INSTALL_DIR}/zotac-zone-hid.ko
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable zotac-zone-drivers.service

cat > /usr/lib/udev/rules.d/99-zotac-zone.rules << 'EOF'
KERNEL=="hidraw*", ATTRS{idVendor}=="1ee9", ATTRS{idProduct}=="1590", MODE="0666"
EOF

echo "uinput" > /usr/lib/modules-load.d/zotac-uinput.conf

### Drop build-only packages before finalizing (dracut dislikes kernel-devel in the image)
depmod -a "${KERNEL_VERSION}"
dnf5 remove -y "kernel-devel-${KERNEL_VERSION}" gcc make wget
rm -rf "$BUILD_DIR"

cp /ctx/files/usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
cp /ctx/files/usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg
