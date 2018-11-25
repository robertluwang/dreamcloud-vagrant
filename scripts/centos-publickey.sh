#!/bin/bash
# centos base box public key script for packer
# Robert Wang @github.com/robertluwang
# Jan 4th, 2018

# reset public key 
mkdir -p /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh
curl -sSLo /home/vagrant/.ssh/authorized_keys  https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

sed -i 's/^#AuthorizedKeysFile/AuthorizedKeysFile/'  /etc/ssh/sshd_config

systemctl restart sshd.service
