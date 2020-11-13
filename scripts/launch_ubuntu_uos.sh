#!/bin/bash

# pci devices for passthru
declare -A passthru_vpid
declare -A passthru_bdf
 
passthru_vpid=(
["ethernet"]="8086 1539"
)
passthru_bdf=(
["ethernet"]="0000:04:00.0"
)
 
function tap_net() {
# create a unique tap device for each VM
tap=$1
tap_exist=$(ip a | grep "$tap" | awk '{print $1}')
if [ "$tap_exist"x != "x" ]; then
  echo "tap device existed, reuse $tap"
else
  ip tuntap add dev $tap mode tap
fi
 
# if acrn-br0 exists, add VM's unique tap device under it
br_exist=$(ip a | grep acrn-br0 | awk '{print $1}')
if [ "$br_exist"x != "x" -a "$tap_exist"x = "x" ]; then
  echo "acrn-br0 bridge aleady exists, adding new tap device to it..."
  ip link set "$tap" master acrn-br0
  ip link set dev "$tap" down
  ip link set dev "$tap" up
fi
}
 
function launch_ubuntu()
{
#vm-name used to generate uos-mac address
mac=$(cat /sys/class/net/e*/address)
vm_name=post_vm_id$1
mac_seed=${mac:0:17}-${vm_name}
 
#check if the vm is running or not
vm_ps=$(pgrep -a -f acrn-dm)
result=$(echo $vm_ps | grep -w "${vm_name}")
if [[ "$result" != "" ]]; then
  echo "$vm_name is running, can't create twice!"
  exit
fi
 
modprobe pci_stub
# Passthrough ETHERNET
echo ${passthru_vpid["ethernet"]} > /sys/bus/pci/drivers/pci-stub/new_id
echo ${passthru_bdf["ethernet"]} > /sys/bus/pci/devices/${passthru_bdf["ethernet"]}/driver/unbind
echo ${passthru_bdf["ethernet"]} > /sys/bus/pci/drivers/pci-stub/bind
 
mem_size=8192M
#interrupt storm monitor for pass-through devices, params order:
#threshold/s,probe-period(s),intr-inject-delay-time(ms),delay-duration(ms)
intr_storm_monitor="--intr_monitor 10000,10,1,100"
 
#logger_setting, format: logger_name,level; like following
logger_setting="--logger_setting console,level=4;kmsg,level=3;disk,level=5"
 
#for pm by vuart setting
pm_channel="--pm_notify_channel uart "
pm_by_vuart="--pm_by_vuart pty,/run/acrn/life_mngr_"$vm_name
pm_vuart_node=" -s 1:0,lpc -l com2,/run/acrn/life_mngr_"$vm_name
 
# for virt net setting
tap_id=tap_ubuntu_vm$1
tap_net ${tap_id}
 
acrn-dm -A -m $mem_size -s 0:0,hostbridge -U d2795438-25d6-11e8-864e-cb7a18b34643 \
   $logger_setting \
   --mac_seed $mac_seed \
   --ovmf /usr/share/acrn/bios/OVMF.fd \
   --cpu_affinity 1,2,3 \
   $intr_storm_monitor \
   -s 3,virtio-blk,./ROS2SystemUOS.img \
   -s 4,passthru,04/00/0 \
   -s 5,virtio-net,${tap_id} \
   -s 6,virtio-hyper_dmabuf \
   -s 7,virtio-rnd \
   -s 8,xhci,1-2 \
   -s 10,virtio-console,@stdio:stdio_port \
   $pm_channel $pm_by_vuart $pm_vuart_node \
   $vm_name
 
}
 
# offline SOS CPUs except BSP before launch UOS
for i in `ls -d /sys/devices/system/cpu/cpu[1-99]`; do
        online=`cat $i/online`
        idx=`echo $i | tr -cd "[1-99]"`
        echo cpu$idx online=$online
        if [ "$online" = "1" ]; then
                echo 0 > $i/online
                echo $idx > /sys/class/vhm/acrn_vhm/offline_cpu
        fi
done
 
launch_ubuntu 1