#!/bin/bash
#  ubuntu 20.04 k8s 1.21 box provision script for packer  
#  Robert Wang
#  Sept 22, 2021

# update/upgrade system 
apt-get update && apt-get upgrade -y 

# install docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

usermod -aG docker vagrant

# turn off swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# install k8s 
echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list
curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-get update && apt-get install -y -q kubelet=1.21.4-00 kubeadm=1.21.4-00 kubectl=1.21.4-00 
apt-mark hold kubelet kubeadm kubectl
