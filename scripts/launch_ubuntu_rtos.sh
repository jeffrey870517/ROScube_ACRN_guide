#!/bin/bash
 
# set -x
 
# pci devices for passthru
declare -A passthru_vpid
declare -A passthru_bdf
 
passthru_vpid=(
["ethernet"]="8086 1539"
)
passthru_bdf=(
["ethernet"]="0000:06:00.0"
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
 
function launch_hard_rt_vm()
{
#vm-name used to generate uos-mac address
mac=$(cat /sys/class/net/e*/address)
vm_name=hard_rtvm
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
 
mem_size=2048M
#interrupt storm monitor for pass-through devices, params order:
#threshold/s,probe-period(s),intr-inject-delay-time(ms),delay-duration(ms)
intr_storm_monitor="--intr_monitor 10000,10,1,100"
 
#logger_setting, format: logger_name,level; like following
logger_setting="--logger_setting console,level=4;kmsg,level=3;disk,level=5"
 
# for pm setting
pm_channel="--pm_notify_channel uart "
pm_by_vuart="--pm_by_vuart tty,/dev/ttyS1"
 
# for virt net setting
tap_id=tap_rtvm
tap_net ${tap_id}
 
acrn-dm -A -m $mem_size -s 0:0,hostbridge \
  -U 495ae2e5-2603-4d64-af76-d4bc5a8ec0e5 \
  --mac_seed $mac_seed \
  --lapic_pt \
  --ovmf /usr/share/acrn/bios/OVMF.fd \
  --rtvm \
  --virtio_poll 1000000 \
  --cpu_affinity 5 \
  -s 3,virtio-blk,./ROS2SystemRTOS.img \
  -s 4,passthru,06/00/0 \
  -s 5,virtio-net,${tap_id} \
  -s 9,virtio-console,@stdio:stdio_port \
  $logger_setting \
  $pm_channel $pm_by_vuart \
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
 
echo 350 > /sys/class/drm/card0/gt_max_freq_mhz
echo 350 > /sys/class/drm/card0/gt_min_freq_mhz
echo 350 > /sys/class/drm/card0/gt_boost_freq_mhz
 
launch_hard_rt_vm