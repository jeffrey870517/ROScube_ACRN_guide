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

acrn_net=/etc/init.d/acrn-net
if [ -f ${acrn_net} ]; then
  sudo update-rc.d -f acrn_net remove
  sudo rm ${acrn_net}
fi
