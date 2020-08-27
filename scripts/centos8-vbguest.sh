#!/bin/bash
# centos8 base box virtualbox guest tool script for packer
# Robert Wang @github.com/robertluwang
# Aug 26, 2020

yum install kernel-devel gcc bzip2 tar make elfutils-libelf-devel -y

mount -o loop,ro VBoxGuestAdditions.iso /mnt
yes | sh /mnt/VBoxLinuxAdditions.run || echo "VBoxLinuxAdditions.run exited $? and is suppressed."
rm VBoxGuestAdditions.iso
umount /mnt
