#!/bin/bash
# ---------------------------------------------------------------------------
# ROS2 SystemOS Real-time Project Disable ACRN Virt-Net Script

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
if [ -f ${acrn_net_service} ]; then
  sudo systemctl disable ${acrn_net}
  sudo rm ${acrn_net_service}
fi
if [ -f ${acrn_net_sh} ]; then
  sudo rm ${acrn_net_sh}
fi
