# launch ubuntu20 dev vm from dreancloud-ubuntu20

I build [dreamcloud/ubuntu20](https://app.vagrantup.com/dreamcloud/boxes/ubuntu20) vagrant box as practise, it is a dev ready vm:

- Guest Tool, shared folder 
- gcc/git/python3/pip3

Here is demo how to launch ubuntu20 vm from this base, add 2nd host-only interface for private network.

## Vagrantfile
```
Vagrant.configure("2") do |config|
    config.vm.box="dreamcloud/ubuntu20"
    config.ssh.insert_key = false
    config.vm.box_check_update = false
    
    config.vm.define "ubuntu20" do |ub20|
        ub20.vm.hostname = "ubuntu20"
        ub20.vm.network :private_network, ip: "192.168.99.30"

        ub20.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
            vb.name="ubuntu20"
            vb.memory=1024
        end
    end
end
```
## vagrant up
```
/mnt/c/vagrant/ubuntu20$ vagrant.exe up
Bringing machine 'ubuntu20' up with 'virtualbox' provider...
==> ubuntu20: Box 'dreamcloud/ubuntu20' could not be found. Attempting to find and install...
    ubuntu20: Box Provider: virtualbox
    ubuntu20: Box Version: >= 0
==> ubuntu20: Loading metadata for box 'dreamcloud/ubuntu20'
    ubuntu20: URL: https://vagrantcloud.com/dreamcloud/ubuntu20
==> ubuntu20: Adding box 'dreamcloud/ubuntu20' (v2020.08.27) for provider: virtualbox
    ubuntu20: Downloading: https://vagrantcloud.com/dreamcloud/boxes/ubuntu20/versions/2020.08.27/providers/virtualbox.box
Download redirected to host: vagrantcloud-files-production.s3.amazonaws.com
    ubuntu20:
==> ubuntu20: Successfully added box 'dreamcloud/ubuntu20' (v2020.08.27) for 'virtualbox'!
==> ubuntu20: Importing base box 'dreamcloud/ubuntu20'...
==> ubuntu20: Matching MAC address for NAT networking...
==> ubuntu20: Setting the name of the VM: ubuntu20
==> ubuntu20: Fixed port collision for 22 => 2222. Now on port 2200.
==> ubuntu20: Clearing any previously set network interfaces...
==> ubuntu20: Preparing network interfaces based on configuration...
    ubuntu20: Adapter 1: nat
    ubuntu20: Adapter 2: hostonly
==> ubuntu20: Forwarding ports...
    ubuntu20: 22 (guest) => 2200 (host) (adapter 1)
==> ubuntu20: Running 'pre-boot' VM customizations...
==> ubuntu20: Booting VM...
==> ubuntu20: Waiting for machine to boot. This may take a few minutes...
    ubuntu20: SSH address: 127.0.0.1:2200
    ubuntu20: SSH username: vagrant
    ubuntu20: SSH auth method: private key
==> ubuntu20: Machine booted and ready!
==> ubuntu20: Checking for guest additions in VM...
==> ubuntu20: Setting hostname...
==> ubuntu20: Configuring and enabling network interfaces...
==> ubuntu20: Mounting shared folders...
    ubuntu20: /vagrant => C:/vagrant/ubuntu20
```
## test vagrant box
shared folder mounted properly,
```
vagrant@ubuntu20:~$ df -h
Filesystem                  Size  Used Avail Use% Mounted on
udev                        467M     0  467M   0% /dev
tmpfs                        99M  620K   98M   1% /run
/dev/mapper/vgvagrant-root   62G  1.6G   57G   3% /
tmpfs                       491M     0  491M   0% /dev/shm
tmpfs                       5.0M     0  5.0M   0% /run/lock
tmpfs                       491M     0  491M   0% /sys/fs/cgroup
/dev/sda1                   511M  4.0K  511M   1% /boot/efi
vagrant                     476G  403G   73G  85% /vagrant
tmpfs                        99M     0   99M   0% /run/user/900

vagrant@ubuntu20:~$ mount |grep vagrant
/dev/mapper/vgvagrant-root on / type ext4 (rw,relatime,errors=remount-ro)
vagrant on /vagrant type vboxsf (rw,nodev,relatime,iocharset=utf8,uid=900,gid=900)
```
NIC and Internet access,
```
Keep in mind the network interface managed by netplan since ubuntu 18.04, 

vagrant@ubuntu20:/etc$ cd netplan/
vagrant@ubuntu20:/etc/netplan$ ll
total 16
drwxr-xr-x  2 root root 4096 Aug 27 13:53 ./
drwxr-xr-x 78 root root 4096 Aug 27 13:53 ../
-rw-r--r--  1 root root  195 Aug 27 12:50 01-netcfg.yaml
-rw-r--r--  1 root root  114 Aug 27 13:53 50-vagrant.yaml
vagrant@ubuntu20:/etc/netplan$ cat 01-netcfg.yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: yes

vagrant@ubuntu20:/etc/netplan$ cat 50-vagrant.yaml
---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.99.30/24

vagrant@ubuntu20:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:1d:48:b4 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 86278sec preferred_lft 86278sec
    inet6 fe80::a00:27ff:fe1d:48b4/64 scope link
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:de:72:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.99.30/24 brd 192.168.99.255 scope global enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fede:728e/64 scope link
       valid_lft forever preferred_lft forever
       
vagrant@ubuntu20:~$ ip r
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
192.168.99.0/24 dev enp0s8 proto kernel scope link src 192.168.99.30

vagrant@ubuntu20:~$ ping -c 2 google.ca
PING google.ca (216.58.194.131) 56(84) bytes of data.
64 bytes from dfw06s49-in-f3.1e100.net (216.58.194.131): icmp_seq=1 ttl=103 time=57.5 ms
64 bytes from dfw06s49-in-f3.1e100.net (216.58.194.131): icmp_seq=2 ttl=103 time=57.6 ms
```
