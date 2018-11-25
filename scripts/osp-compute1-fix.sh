#!/bin/bash
#  rhel7.3 osp10 compute1 fix provision script for packer  
#  Robert Wang
#  Sept 24th, 2018

nics=`ls -ltr /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|grep -v ifcfg-br-ex|awk '{print $9}'|cut -d\- -f2|sort|head -2`
hoif=`echo $nics|awk '{print $2}'`
hoip=`ip addr show $hoif|grep $hoif|grep global|awk '{print $2}'|cut -d/ -f1`

sed -i  "/localhost/d" /etc/hosts
sed -i  "/127.0.0.1/d" /etc/hosts
sed -i  "/compute/d" /etc/hosts

echo "127.0.0.1    lo localhost" |sudo tee -a /etc/hosts
echo "$hoip    compute1" |sudo tee -a /etc/hosts

