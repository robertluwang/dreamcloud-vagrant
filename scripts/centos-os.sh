#!/bin/bash
#  centos openstack with packstack provision script for packer  
#  Robert Wang
#  Oct 30th, 2018
#  $1 - openstack version, default is rocky

set -x

# presetup
systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

# sw repo
if [ -z "$1" ];
then  
    yum install -y centos-release-openstack-rocky
else
    yum install -y centos-release-openstack-$1
fi
yum update -y 

# install openvswitch

yum install -y openvswitch
systemctl start openvswitch

# install packstack
yum install -y openstack-packstack
yum install -y openstack-utils

# run packstack
packstack --gen-answer-file=packstack_`date +"%Y-%m-%d"`.conf
cp packstack_`date +"%Y-%m-%d"`.conf latest_packstack.conf

natif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -1`
natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`

osif=$natif
osip=$natip

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

# update /etc/hosts

sed -i  "/localhost/d" /etc/hosts
sed -i  "/127.0.0.1/d" /etc/hosts
sed -i  "/$osip/d" /etc/hosts

echo "127.0.0.1    lo localhost" | sudo tee -a /etc/hosts
echo "$osip    "`hostname` |sudo tee -a /etc/hosts

$CONFIGSET CONFIG_CONTROLLER_HOST $osip
$CONFIGSET CONFIG_COMPUTE_HOSTS $osip
$CONFIGSET CONFIG_NETWORK_HOSTS $osip
$CONFIGSET CONFIG_STORAGE_HOST $osip
$CONFIGSET CONFIG_SAHARA_HOST $osip
$CONFIGSET CONFIG_AMQP_HOST $osip
$CONFIGSET CONFIG_MARIADB_HOST $osip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$osip
$CONFIGSET CONFIG_REDIS_HOST $osip

$CONFIGSET CONFIG_DEFAULT_PASSWORD demo
$CONFIGSET CONFIG_KEYSTONE_ADMIN_PW demo
$CONFIGSET CONFIG_HEAT_KS_PW demo
$CONFIGSET CONFIG_HEAT_DOMAIN_PASSWORD demo

$CONFIGSET CONFIG_PROVISION_DEMO n
$CONFIGSET CONFIG_HORIZON_SSL n

$CONFIGSET CONFIG_CINDER_INSTALL y
$CONFIGSET CONFIG_SWIFT_INSTALL y
$CONFIGSET CONFIG_CEILOMETER_INSTALL y
$CONFIGSET CONFIG_PANKO_INSTALL y
$CONFIGSET CONFIG_AODH_INSTALL y
$CONFIGSET CONFIG_HEAT_INSTALL y

$CONFIGSET CONFIG_NEUTRON_L3_EXT_BRIDGE 
$CONFIGSET CONFIG_NEUTRON_ML2_TYPE_DRIVERS flat,vxlan
$CONFIGSET CONFIG_NEUTRON_ML2_VXLAN_GROUP 239.1.1.2
$CONFIGSET CONFIG_NEUTRON_ML2_VNI_RANGES 1000:2000
$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS physnet1:br-ex
$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$osif
$CONFIGSET CONFIG_KEYSTONE_API_VERSION v3

packstack --answer-file latest_packstack.conf --timeout=1800 || echo "packstack exited $? and is suppressed."

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_*
sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /home/vagrant/keystonerc_*
sed  -i "s/^[ \t]*//" /root/keystonerc_*
sed  -i "s/^[ \t]*//" /home/vagrant/keystonerc_*
cp /root/keystonerc_* /home/vagrant
chown vagrant:vagrant /home/vagrant/keystonerc*

