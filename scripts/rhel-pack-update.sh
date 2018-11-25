#!/bin/bash
# rhel7-pack-update.sh
# rhel7 base openstack box packstack ip update script for packer
# Robert Wang @github.com/robertluwang
# Sept 24th, 2018
# $1 - compute1 ip

set -x

CONFIGSET="openstack-config --set latest_packstack.conf general "
CONFIGGET="openstack-config --get latest_packstack.conf general "

# check how many interface
nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2`
numif=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2|wc -l`

# if only one NIC is NAT; if two NICs then pick up 2nd Hostonly as openstack network 

ipconf=`$CONFIGGET CONFIG_CONTROLLER_HOST`

if [ $numif = 2 ]
then
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ "$natip" = "" ];then
        natip=`ip addr show br-ex|grep "global dynamic br-ex"|awk '{print $2}'|cut -d/ -f1`
    fi
    hoif=`echo $nics|awk '{print $2}'`
    hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`
    osif=$hoif
    osip=$hoip
else
    natif=`echo $nics|awk '{print $1}'`
    natip=`ip addr show $natif|grep $natif|grep global|awk '{print $2}'|cut -d/ -f1`
    if [ "$natip" = "" ];then
        natip=`ip addr show br-ex|grep "global dynamic br-ex"|awk '{print $2}'|cut -d/ -f1`
    fi

    curl -LO https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/scripts/rhel7-ovs-fix.sh
    chmod +x rhel7-ovs-fix.sh
    ./rhel7-ovs-fix.sh enp0s3 $natip
    exit 0 
fi

ovsif=$natif
ovsip=$natip

# update /etc/hosts

sed -i  "/localhost/d" /etc/hosts
sed -i  "/127.0.0.1/d" /etc/hosts
sed -i  "/$natip/d" /etc/hosts
sed -i  "/$osip/d" /etc/hosts

echo "127.0.0.1    lo localhost" | sudo tee -a /etc/hosts
echo "$osip    "`hostname` |sudo tee -a /etc/hosts

# update latest_packstack.conf

$CONFIGSET CONFIG_CONTROLLER_HOST $osip
if [ -z "$1" ] ;then
    $CONFIGSET CONFIG_COMPUTE_HOSTS $osip   
else 
    $CONFIGSET CONFIG_COMPUTE_HOSTS $osip,$1
fi  
$CONFIGSET CONFIG_NETWORK_HOSTS $osip
$CONFIGSET CONFIG_STORAGE_HOST $osip
$CONFIGSET CONFIG_SAHARA_HOST $osip
$CONFIGSET CONFIG_AMQP_HOST $osip
$CONFIGSET CONFIG_MARIADB_HOST $osip
$CONFIGSET CONFIG_MONGODB_HOST $osip
$CONFIGSET CONFIG_KEYSTONE_LDAP_URL ldap://$osip
$CONFIGSET CONFIG_REDIS_HOST $osip

$CONFIGSET CONFIG_DEFAULT_PASSWORD demo
$CONFIGSET CONFIG_KEYSTONE_ADMIN_PW demo
$CONFIGSET CONFIG_HEAT_KS_PW demo
$CONFIGSET CONFIG_HEAT_DOMAIN_PASSWORD demo

$CONFIGSET CONFIG_PROVISION_DEMO n

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
$CONFIGSET CONFIG_NEUTRON_OVS_BRIDGE_IFACES br-ex:$ovsif
$CONFIGSET CONFIG_KEYSTONE_API_VERSION v3

# SSL 
$CONFIGSET CONFIG_HORIZON_SSL y
$CONFIGSET CONFIG_SSL_CACERT_SELFSIGN y
$CONFIGSET CONFIG_AMQP_ENABLE_SSL y

#$CONFIGSET CONFIG_SSL_CACERT_FILE /etc/pki/tls/certs/localhost.crt
#$CONFIGSET CONFIG_SSL_CACERT_KEY_FILE /etc/pki/tls/private/localhost.key 
$CONFIGSET CONFIG_SSL_CERT_DIR /root/packstackca

# update source file

sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /root/keystonerc_*
sed -i "/export\ OS_AUTH_URL=/c export\ OS_AUTH_URL=http://$osip:5000/v3" /home/vagrant/keystonerc_*
sed  -i "s/^[ \t]*//" /root/keystonerc_*
sed  -i "s/^[ \t]*//" /home/vagrant/keystonerc_*
cp /root/keystonerc_* /home/vagrant
chown vagrant:vagrant /home/vagrant/keystonerc*

if [ -z "$1" ] ;then
    packstack --answer-file latest_packstack.conf --timeout=1800 || echo "packstack exited $? and is suppressed."   
else 
    echo
    echo "packstack answer file latest_packstack.conf is updated for compute1 node "$1
    echo make sure compute1 node is running and ssh to allinone node to run packstack manually as vagrant, 
    echo sudo packstack --answer-file latest_packstack.conf --timeout=1800 
    echo
fi 





