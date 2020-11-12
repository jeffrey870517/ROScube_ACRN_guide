Getting Started Guide for ACRN Industry Scenario with ROScube-I
###############################################################

.. contents::
   :local:
   :depth: 1

Verified version
****************

- Ubuntu version: **18.04**
- GCC version: **7.5.0**
- ACRN-hypervisor branch: **release_2.1**
- ACRN-Kernel (Service VM kernel): **release_2.1**
- RT kernel for Ubuntu User OS: TODO
- HW: `ROScube-I <https://www.adlinktech.com/Products/ROS2_Solution/ROS2_Controller/ROScube-I?lang=en>`_

Architecture
************

In the tutorial, we'll guide you how install ACRN Industry Scenario on ROScube-I.
The scenario will be like the following:

TODO: Add architecture

Prerequisites
*************

* Install Ubuntu 18.04 on ROScube-I.

* Modify the following BIOS settings.

.. csv-table::
   :widths: 15, 30, 10

   "Hyper-threading", "Advanced -> CPU Configuration", "Disabled"
   "Intel (VMX) Virtualization", "Advanced -> CPU Configuration", "Enabled"
   "Intel(R) SpeedStep(tm)", "Advanced -> CPU Configuration", "Disabled"
   "Intel(R) Speed Shift Technology", "Advanced -> CPU configuration", "Disabled"
   "Turbo Mode", "Advanced -> CPU configuration", "Disabled"
   "C States", "Advanced -> CPU configuration", "Disabled"
   "VT-d", "Chipset -> System Agent (SA) Configuration", "Enabled"
   "DVMT-Pre Allocated", "Chipset -> System Agent (SA) Configuration -> Graphics Configuration", "64M"

Install ACRN hypervisor
***********************

Setup Environment
=================

#. Open ``/etc/default/grub/`` and add ``idle=nomwait intel_pstate=disable`` in the end of GRUB_CMDLINE_LINUX_DEFAULT.

   .. figure:: images/rqi-acrn-grub.png

#. Update grub and then reboot.

   .. code-block:: bash

     sudo update-grub
     sudo reboot

#. Install the necessary libraries:

   .. code-block:: bash

     sudo apt update
     sudo apt install -y gcc \
       git \
       make \
       gnu-efi \
       libssl-dev \
       libpciaccess-dev \
       uuid-dev \
       libsystemd-dev \
       libevent-dev \
       libxml2-dev \
       libusb-1.0-0-dev \
       python3 \
       python3-pip \
       libblkid-dev \
       e2fslibs-dev \
       pkg-config \
       libnuma-dev \
       liblz4-tool \
       flex \
       bison
     sudo pip3 install kconfiglib

#. Get code from GitHub.

   .. code-block:: bash

     mkdir ~/acrn && cd ~/acrn
     git clone https://github.com/projectacrn/acrn-hypervisor -b release_2.1
     cd acrn-hypervisor

Configure Hypervisor
====================

#. Parse system information.

   .. code-block:: bash

     sudo apt install -y cpuid msr-tools
     cd ~/acrn/acrn-hypervisor/misc/acrn-config/target/
     sudo python3 board_parser.py ros-cube-cfl
     cp ~/acrn/acrn-hypervisor/misc/acrn-config/target/out/ros-cube-cfl.xml ~/acrn/acrn-hypervisor/misc/acrn-config/xmls/board-xmls/

#. Run ACRN configuration app and it'll open a browser page.

   .. code-block:: bash
 
     cd ~/acrn/acrn-hypervisor/misc/acrn-config/config_app
     sudo pip3 install -r requirements
     python3 app.py

   .. figure:: images/rqi-acrn-config-web.png

#. Select "Import Board info".

   .. figure:: images/rqi-acrn-config-import-board.png

#. Select target board name.

   .. figure:: images/rqi-acrn-config-select-board.png

#. Select "Scnario Setting" and choose "Load a default scenario".

   .. figure:: images/rqi-acrn-config-scenario-settings.png

#. Settings "HV": You can ignore this if your RAM is <= 16GB.

   .. figure:: images/rqi-acrn-config-hv-settings.png

#. Settings "VM0": Select the hard disk currently used.

   .. figure:: images/rqi-acrn-config-vm0-settings.png

#. Settings "VM1": Enable all the cpu_affinity.

   .. figure:: images/rqi-acrn-config-vm1-settings.png

#. Settings "VM2": Setup RT flags and enable all the cpu_affinity.

   .. figure:: images/rqi-acrn-config-vm2-settings1.png

   .. figure:: images/rqi-acrn-config-vm2-settings2.png

#. Export XML.

   .. figure:: images/rqi-acrn-config-export-xml.png

   .. figure:: images/rqi-acrn-config-export-xml-submit.png

#. Generate configuration files.

   .. figure:: images/rqi-acrn-config-generate-config.png

   .. figure:: images/rqi-acrn-config-generate-config-submit.png

#. Close the browser and stop the process (Ctrl+C).

#. Build hypervisor

   .. code-block:: bash

     cd ~/acrn/acrn-hypervisor
     make all BOARD_FILE=misc/acrn-config/xmls/board-xmls/ros-cube-cfl.xml SCENARIO_FILE=misc/acrn-config/xmls/config-xmls/ros-cube-cfl/user_defined/industry_ROS2SystemOS.xml RELEASE=0

#. Install hypervisor

   .. code-block:: bash

     sudo make install
     sudo mkdir /boot/acrn
     sudo cp ~/acrn/acrn-hypervisor/build/hypervisor/acrn.bin /boot/acrn/

Install Service VM kernel
*************************

#. Get code from GitHub

   .. code-block:: bash

     cd ~/acrn
     git clone https://github.com/projectacrn/acrn-kernel -b release_2.1
     cd acrn-kernel

#. Restore default ACRN configuration.

   .. code-block:: bash
 
     cp kernel_config_uefi_sos .config
     make olddefconfig
     sed -ri '/CONFIG_LOCALVERSION=/s/=.+/="-ROS2SystemSOS"/g' .config
     sed -i '/CONFIG_PINCTRL_CANNONLAKE/c\CONFIG_PINCTRL_CANNONLAKE=m' .config

#. Build Service VM kernel. It'll take some time.

   .. code-block:: bash
 
     make all

#. Install kernel and module.

   .. code-block:: bash
 
     sudo make modules_install
     sudo cp arch/x86/boot/bzImage /boot/acrn-ROS2SystemSOS

#. Get the UUID and PARTUUID.

   .. code-block:: bash

     sudo blkid /dev/sda*

   .. note:: The UUID and PARTUUID we needs should be ``/dev/sda2``, which is ``TYPE="ext4"``.
             Just like the following graph:
   
   .. figure:: images/rqi-acrn-blkid.png

#. Update ``/etc/grub.d/40_custom`` as below. Remember to edit <UUID> and <PARTUUID> to yours.

   .. code-block:: bash
 
     menuentry "ACRN Multiboot Ubuntu Service VM" --id ubuntu-service-vm {
       load_video
       insmod gzio
       insmod part_gpt
       insmod ext2

       search --no-floppy --fs-uuid --set <UUID>
       echo 'loading ACRN Service VM...'
       multiboot2 /boot/acrn/acrn.bin  root=PARTUUID="<PARTUUID>"
       module2 /boot/acrn-ROS2SystemSOS Linux_bzImage
     }

#. Update ``/etc/default/grub`` to make grub menu visible and load Service VM as default.

   .. code-block:: bash

     GRUB_DEFAULT=ubuntu-service-vm
     # GRUB_TIMEOUT_STYLE=hidden
     GRUB_TIMEOUT=5 

#. Then update grub and reboot.

   .. code-block:: bash

     sudo update-grub
     sudo reboot

#. ``ACRN Multiboot Ubuntu Service VM`` entry will be shown grub menu and choose it to load ACRN.
   You can check whether the installation is successful or not by dmesg.

   .. code-block:: bash

     $ sudo dmesg | grep ACRN (TODO: Add result)

Install User VM
***************

We need to create User VM image by QEMU/KVM first.
**Please run the following commands on native Linux kernel, or you'll get the error message.**

#. Install necessary packages

   .. code-block:: bash

     sudo apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager ovmf
     sudo reboot

#. Start virtual machine manager application.

   .. code-block:: bash

     sudo virt-manager

#. TODO: Add graph

#. Install dependency

   .. code-block:: bash

     sudo -E apt-get install iasl
 
     cd /tmp
     wget https://acpica.org/sites/acpica/files/acpica-unix-20191018.tar.gz
     tar zxvf acpica-unix-20191018.tar.gz

     cd acpica-unix-20191018
     make clean && make iasl
     sudo cp ./generate/unix/bin/iasl /usr/sbin/

#. Convert KVM image file format

   .. code-block:: bash

     mkdir -p ~/acrn/uosVM
     cd ~/acrn/uosVM
     sudo qemu-img convert -f qcow2 -O raw /var/lib/libvirt/images/ROS2SystemUOS.qcow2 ./ROS2SystemUOS.img

#. Prepare a Launch Script File

   .. code-block:: bash

     wget TODO (launch file)
     chmod +x ./launch_ubuntu_uos.sh 

#. Launch the VM

   .. code-block:: bash

     sudo ./launch_ubuntu_uos.sh

Install Real-Time VM
********************

#. Clone RTVM from User VM. TODO: Add graph

#. Install Xenomai kernel. TODO: found the tutorial.

#. Convert KVM image file format

   .. code-block:: bash

     mkdir -p ~/acrn/rtosVM
     cd ~/acrn/rtosVM
     sudo qemu-img convert -f qcow2 -O raw /var/lib/libvirt/images/ROS2SystemRTOS.qcow2 ./ROS2SystemRTOS.img

#. Create a new launch file

   .. code-block:: bash

     wget TODO (launch file)
     chmod +x ./launch_rtos.sh

#. Launch the VM

   .. code-block:: bash

     sudo ./launch_ubuntu_rtos.sh
