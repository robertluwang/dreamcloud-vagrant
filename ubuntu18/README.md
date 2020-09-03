# launch ubuntu18 dev vm from dreancloud-ubuntu18

I build [dreamcloud/ubuntu18](https://app.vagrantup.com/dreamcloud/boxes/ubuntu18) vagrant box as practise, it is a dev ready vm:

- Guest Tool, shared folder 
- gcc/git/python3/pip3

Here is demo how to launch ubuntu18 vm from this base, add 2nd host-only interface for private network.

## Vagrantfile
```
Vagrant.configure("2") do |config|
    config.vm.box="ub18"
    config.ssh.insert_key = false
    config.vm.box_check_update = false
    
    config.vm.define "ubuntu18" do |ub18|
        ub18.vm.hostname = "ubuntu18"
        ub18.vm.network :private_network, ip: "192.168.20.10"

        ub18.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
            vb.name="ubuntu18"
            vb.memory=1024
        end
    end
End
```
## vagrant up
```
/mnt/c/vagrant/ubuntu18$ vagrant.exe up
Bringing machine 'ubuntu18' up with 'virtualbox' provider...
==> ubuntu18: Importing base box 'dreamcloud/ubuntu18'...
==> ubuntu18: Matching MAC address for NAT networking...
==> ubuntu18: Setting the name of the VM: ubuntu18
==> ubuntu18: Clearing any previously set network interfaces...
==> ubuntu18: Preparing network interfaces based on configuration...
    ubuntu18: Adapter 1: nat
    ubuntu18: Adapter 2: hostonly
==> ubuntu18: Forwarding ports...
    ubuntu18: 22 (guest) => 2222 (host) (adapter 1)
==> ubuntu18: Running 'pre-boot' VM customizations...
==> ubuntu18: Booting VM...
==> ubuntu18: Waiting for machine to boot. This may take a few minutes...
    ubuntu18: SSH address: 127.0.0.1:2222
    ubuntu18: SSH username: vagrant
    ubuntu18: SSH auth method: private key
==> ubuntu18: Machine booted and ready!
==> ubuntu18: Checking for guest additions in VM...
==> ubuntu18: Setting hostname...
==> ubuntu18: Configuring and enabling network interfaces...
==> ubuntu18: Mounting shared folders...
    ubuntu18: /vagrant => C:/vagrant/ubuntu18

```
## test vagrant box
shared folder mounted properly,
```
vagrant@ubuntu18:~$ df -h
Filesystem                    Size  Used Avail Use% Mounted on
udev                          473M     0  473M   0% /dev
tmpfs                          99M  580K   98M   1% /run
/dev/mapper/vagrant--vg-root   62G  1.9G   57G   4% /
tmpfs                         493M     0  493M   0% /dev/shm
tmpfs                         5.0M     0  5.0M   0% /run/lock
tmpfs                         493M     0  493M   0% /sys/fs/cgroup
vagrant                       476G  393G   83G  83% /vagrant
tmpfs                          99M     0   99M   0% /run/user/1000

vagrant@ubuntu18:~$ mount |grep vagrant
/dev/mapper/vagrant--vg-root on / type ext4 (rw,relatime,errors=remount-ro,data=ordered)
vagrant on /vagrant type vboxsf (rw,nodev,relatime,iocharset=utf8,uid=1000,gid=1000)
```
keep in mind the network interface managed by netplan, 
```
vagrant@ubuntu18:~$ ls -ltr /etc/netplan/
total 8
-rw-r--r-- 1 root root 195 Sep  3 15:54 01-netcfg.yaml
-rw-r--r-- 1 root root 114 Sep  3 23:10 50-vagrant.yaml
vagrant@ubuntu18:~$ cat /etc/netplan/01-netcfg.yaml
# This file describes the network interfaces available on your system
# For more information, see netplan(5).
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s3:
      dhcp4: yes

vagrant@ubuntu18:~$ cat /etc/netplan/50-vagrant.yaml
---
network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s8:
      addresses:
      - 192.168.20.10/24
```
NIC and Internet access, 
```
vagrant@ubuntu18:~$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:74:ce:fe brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3
       valid_lft 86283sec preferred_lft 86283sec
    inet6 fe80::a00:27ff:fe74:cefe/64 scope link
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:50:54:7f brd ff:ff:ff:ff:ff:ff
    inet 192.168.20.10/24 brd 192.168.20.255 scope global enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe50:547f/64 scope link
       valid_lft forever preferred_lft forever

vagrant@ubuntu18:~$ ip r
default via 10.0.2.2 dev enp0s3 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15
10.0.2.2 dev enp0s3 proto dhcp scope link src 10.0.2.15 metric 100
192.168.20.0/24 dev enp0s8 proto kernel scope link src 192.168.20.10

vagrant@ubuntu18:~$ cat /etc/resolv.conf
nameserver 127.0.0.53
options edns0

vagrant@ubuntu18:~$ ping -c 2 google.ca
PING google.ca (172.217.9.163) 56(84) bytes of data.
64 bytes from dfw25s27-in-f3.1e100.net (172.217.9.163): icmp_seq=1 ttl=104 time=65.0 ms
64 bytes from dfw25s27-in-f3.1e100.net (172.217.9.163): icmp_seq=2 ttl=104 time=65.3 ms
```
