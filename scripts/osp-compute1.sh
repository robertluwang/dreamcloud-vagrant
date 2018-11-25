#!/bin/bash
#  rhel7.3 osp10 compute1 provision script for packer  
#  Robert Wang
#  Sept 24th, 2018

systemctl disable firewalld
systemctl stop firewalld
systemctl disable NetworkManager
systemctl stop NetworkManager
systemctl enable network
systemctl start network

yum install -y openstack-utils 



