#!/bin/bash
#  ubuntu openstack with devstack provision script for packer  
#  Robert Wang
#  Feb 6th, 2018

sudo apt install bridge-utils

wget https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py

git clone https://git.openstack.org/openstack-dev/devstack

cd ~/devstack

nics=`cat /etc/netplan/*.yaml|grep -A1 ethernets|egrep -v "\-|ethernets"|cut -d: -f1`

natif=`echo $nics|awk '{print $1}'`
natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

# prepare local.conf
cat <<EOF > local.conf
[[local|localrc]] 
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
HOST_IP_IFACE=$natif
HOST_IP=$natip
GIT_BASE=${GIT_BASE:-https://git.openstack.org}
EOF

# run devstack
./stack.sh  || echo "stack.sh exited $? and is suppressed."
