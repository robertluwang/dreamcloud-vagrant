#!/bin/sh
# ubuntu-devstack-update.sh
# ubuntu base openstack box devstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Feb 5th, 2018

# ubuntu 17.10 uses netplan instead of /etc/network/interfaces
nics=`cat /etc/netplan/*.yaml|grep -A1 ethernets|egrep -v "\-|ethernets"|cut -d: -f1`
numif=`cat /etc/netplan/*.yaml|grep -A1 ethernets|egrep -v "\-|ethernets"|cut -d: -f1 | wc -l`

cd ~/devstack

if [ $numif = 2 ]
then
    # there are 2 NIC, will use 2nd hostonly NIC as openstack ip
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`

    sed -i "/HOST_IP_IFACE=/c HOST_IP_IFACE=$hoif" local.conf
    sed -i "/HOST_IP=/c HOST_IP=$hoip" local.conf

    # run devstack
    ./stack.sh || echo "stack.sh exited $? and is suppressed."
else
    # there is only one default NAT NIC, will use as openstack ip
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

    ipconf=`grep HOST_IP= local.conf|cut -d= -f2`

    if [ $natip = $ipconf ]
    then
        # NAT ip same as ip on conf, just exit
        exit 0
    else
        # NAT ip diff than ip on conf, will replace it 
        sed -i "/HOST_IP_IFACE=/c HOST_IP_IFACE=$natif" local.conf
        sed -i "/HOST_IP=/c HOST_IP=$natip" local.conf

        ./stack.sh || echo "stack.sh exited $? and is suppressed."
    fi
fi
