#!/bin/bash
# ---------------------------------------------------------------------------
# ROS2 SystemOS Real-time Project Enable ACRN Virt-Net Script

# Copyright 2019, ADLINK

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.
# ---------------------------------------------------------------------------

acrn_net=acrn_net
acrn_net_sh=/opt/${acrn_net}.sh
acrn_net_service=/etc/systemd/system/${acrn_net}.service
if [ ! -f ${acrn_net_service} ]; then
  sudo touch ${acrn_net_service}
  echo "
[Unit]
Description=Create ACRN bridge network

[Service]
ExecStart=/opt/acrn_net.sh

[Install]
WantedBy=multi-user.target
" | sudo tee ${acrn_net_service} > /dev/null
fi

if [ ! -f ${acrn_net_sh} ]; then
  sudo touch ${acrn_net_sh}
  echo "#! /bin/sh

set -e

br=$(brctl show | grep acrn-br0)
br=${br-:0:6}

# if bridge not existed
if ! echo $br | grep -q "acrn-br0"; then
  #setup bridge for uos network
  brctl addbr acrn-br0
  brctl addif acrn-br0 eno1
  ifconfig eno1 0
  dhclient acrn-br0
fi

exit 0
" | sudo tee ${acrn_net_sh} > /dev/null

sudo chmod +x ${acrn_net_sh}
sudo systemctl enable ${acrn_net}
sudo systemctl start ${acrn_net}
fi
