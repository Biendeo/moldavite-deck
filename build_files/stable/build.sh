#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y wireshark
chgrp wireshark /usr/sbin/dumpcap
chmod o-rx /usr/sbin/dumpcap

cp /ctx/files/usr/share/plymouth/themes/spinner/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
cp /ctx/files/usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg /usr/share/icons/hicolor/scalable/places/distributor-logo-steamdeck.svg