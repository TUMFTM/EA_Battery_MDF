#!/bin/bash

# This Script should be run after the MATLAB image is flashed to the pi.
# It installs all the necessary dependencies, writes all config files
# and enables everything to run automatically at startup

# execue scripts as root
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

# update, upgrade existing packages
apt update
apt -y upgrade
# install necessary linux packages
apt install -y python3 python3-pip python3-rpi.gpio can-utils isc-dhcp-server hostapd
# install necessary python packages
pip3 install python-can adafruit-ads1x15 numpy

#make model .elf file executable for python
chmod a+x ../model_builds/spmet_30032021_raspberry_live_update_R19b.elf

# create service file for main python skript, to make execution at startup possible
cat << EOF > /etc/systemd/system/dcfc-test-bench.service
[Unit]
Description=DCFC Test Bench Service

[Service]
Environment=PYTHONUNBUFFERED=1
WorkingDirectory=/home/pi/ea_battery_mdf/implementation/auxiliaries/
ExecStart=/usr/bin/python3 /home/pi/ea_battery_mdf/implementation/auxiliaries/dcfc_test_bench.py
User=root
Restart=always

[Install]
WantedBy=multi-user.target
EOF



# configure wifi hotspot of pi
cat << EOF > /etc/hostapd/hostapd.conf
interface=wlan0
driver=nl80211
ssid=DCFC Test Bench x
hw_mode=b
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=ftmbattest
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF

# make hotspot use the right config-file
cat << EOF > /etc/default/hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOF

# configure DHCP-Client (make pi able to receive IP adresses from connected devices)
rfkill unblock wlan
if ! grep "static ip_address=10.1.0.2/24" /etc/dhcpcd.conf; then
cat << EOF >> /etc/dhcpcd.conf
profile static_eth0
static ip_address=10.0.0.2/30
static routers=10.0.0.1
static domain_name_servers=1.1.1.1

interface eth0
fallback static_eth0

interface wlan0
    static ip_address=10.1.0.2/24
    nohook wpa_supplicant
EOF
fi

# configure DHCP-Server (make pi allocate IP adresses to connected devices)
sed -i -E 's/INTERFACESv4="[a-zA-Z0-9]*"/INTERFACESv4="wlan0"/' /etc/default/isc-dhcp-server
cat << EOF > /etc/dhcp/dhcpd.conf
option domain-name "dcfc-bench.lan";

default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet 10.1.0.0 netmask 255.255.255.0 {
        range 10.1.0.3 10.1.0.254;
        option routers 10.1.0.2;
}
EOF

# edit raspberry boot config (to keep fan off at start and to make CAN work)
if ! grep "# CAN Hat" /boot/config.txt; then
cat << EOF >> /boot/config.txt
# CAN Hat
dtoverlay=mcp2515-can0,oscillator=12000000,interrupt=25,spimaxfrequency=2000000

# set fan off at boot
gpio=17=op,dl
EOF
fi

# adding aliases (to make it possible to control testbench with easy commands: start, status, stop)
if ! grep "alias start" /home/pi/.bashrc; then
cat << EOF >> /home/pi/.bashrc
alias start='sudo systemctl restart dcfc-test-bench'
alias status='sudo journalctl -fu dcfc-test-bench -o cat'
alias stop='sudo systemctl stop dcfc-test-bench'
EOF
fi

# restart DHCP Server to apply changes
systemctl restart dhcpcd

# enable and start all the services
systemctl enable --now isc-dhcp-server
systemctl unmask hostapd
systemctl enable --now hostapd
systemctl enable --now dcfc-test-bench

# set timezone and do a NTP sync
timedatectl set-timezone Europe/Berlin
timedatectl set-ntp True

# expand file system
raspi-config --expand-rootfs


