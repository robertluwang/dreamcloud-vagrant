#!/bin/bash
#  centos  base  box  provision  script for packer  
#  Robert Wang
#  Aug 26, 2020

# fix  primary  NAT  interface issue
ifcfgname=`ls /etc/sysconfig/network-scripts|grep ifcfg|grep -v ifcfg-lo|sort|head -1`
sed -i '/ONBOOT=no/ s/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/$ifcfgname
sed -i '/UUID/d' /etc/sysconfig/network-scripts/$ifcfgname

# add user vagrant to sudo group vagrant 
if [ ! `cat /etc/group | grep ^vagrant` ];then
    groupadd vagrant
fi

usermod -a -G vagrant vagrant

if [ -d /etc/sudoers.d/vagrant ];then
    rm /etc/sudoers.d/vagrant  
fi 

touch /etc/sudoers.d/vagrant

echo '%vagrant ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# SELinux to permissive mode
sed -i -e 's/^SELINUX=.*/SELINUX=permissive/' /etc/selinux/config

# update system
yum -y -q update
yum -y -q upgrade 
yum install -y -q git dos2unix wget python3 python3-pip
alternatives --set python /usr/bin/python3






