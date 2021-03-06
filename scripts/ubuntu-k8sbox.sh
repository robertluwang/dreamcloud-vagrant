#!/bin/bash
#  ubuntu 18.04 k8s 1.20.8-00 box provision script for packer  
#  Robert Wang
#  Jun 21, 2021

# update/upgrade system 
apt-get update -y 
apt-get upgrade -y 

# install docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

usermod -aG docker vagrant

# turn off swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# install k8s 
sh -c 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list'
curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-get update -y 
apt-get install -y -q kubelet=1.20.8-00 kubeadm=1.20.8-00 kubectl=1.20.8-00
apt-mark hold kubelet kubeadm kubectl
