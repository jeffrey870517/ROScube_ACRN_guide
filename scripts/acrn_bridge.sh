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

acrn_net=/etc/init.d/acrn-net
if [ ! -f ${acrn_net} ]; then
  sudo touch ${acrn_net}
  echo "#! /bin/sh

### BEGIN INIT INFO
# Provides:             acrn-net
# Required-Start:       $syslog $network
# Required-Stop:        $syslog $network
# Default-Start:        2 3 4 5
# Default-Stop:
# Short-Description:    ADLINK ROS2SystemOS ACRN Virt-Net Settings
### END INIT INFO

set -e

# /etc/init.d/acrn_net: start and stop real-time configuration daemon

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
" | sudo tee ${acrn_net} > /dev/null

sudo chmod +x ${acrn_net}
sudo update-rc.d acrn-net defaults
fi
