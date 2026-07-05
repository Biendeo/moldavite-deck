#!/bin/bash

set -ouex pipefail

### Install packages

dnf5 install -y wireshark
chgrp wireshark /usr/sbin/dumpcap
chmod o-rx /usr/sbin/dumpcap