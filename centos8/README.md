# launch centos8 dev vm from dreancloud-centos8

I build [dreamcloud/centos8](https://app.vagrantup.com/dreamcloud/boxes/centos8) vagrant box as practise, it is a dev ready vm:

- Guest Tool, shared folder 
- gcc/git/python3/pip3

Here is demo how to launch centos vm from this base, add 2nd host-only interface for private network.

## Vagrantfile
```
Vagrant.configure("2") do |config|
    config.vm.box="dreamcloud/centos8"
    config.ssh.insert_key = false
    config.vm.box_check_update = false
    
    config.vm.define "centos8" do |ct8|
        ct8.vm.hostname = "centos8"
        ct8.vm.network :private_network, ip: "192.168.99.20"

        ct8.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
            vb.name="centos8"
            vb.memory=1024
        end
    end
end
```
## vagrant up
```
/mnt/c/vagrant/centos8$ vagrant.exe up
Bringing machine 'centos8' up with 'virtualbox' provider...
==> centos8: Box 'dreamcloud/centos8' could not be found. Attempting to find and install...
    centos8: Box Provider: virtualbox
    centos8: Box Version: >= 0
==> centos8: Loading metadata for box 'dreamcloud/centos8'
    centos8: URL: https://vagrantcloud.com/dreamcloud/centos8
==> centos8: Adding box 'dreamcloud/centos8' (v2020.08.26) for provider: virtualbox
    centos8: Downloading: https://vagrantcloud.com/dreamcloud/boxes/centos8/versions/2020.08.26/providers/virtualbox.box
Download redirected to host: vagrantcloud-files-production.s3.amazonaws.com
    centos8:
==> centos8: Successfully added box 'dreamcloud/centos8' (v2020.08.26) for 'virtualbox'!
==> centos8: Importing base box 'dreamcloud/centos8'...
==> centos8: Matching MAC address for NAT networking...
==> centos8: Setting the name of the VM: centos8
==> centos8: Clearing any previously set network interfaces...
==> centos8: Preparing network interfaces based on configuration...
    centos8: Adapter 1: nat
    centos8: Adapter 2: hostonly
==> centos8: Forwarding ports...
    centos8: 22 (guest) => 2222 (host) (adapter 1)
==> centos8: Running 'pre-boot' VM customizations...
==> centos8: Booting VM...
==> centos8: Waiting for machine to boot. This may take a few minutes...
    centos8: SSH address: 127.0.0.1:2222
    centos8: SSH username: vagrant
    centos8: SSH auth method: private key
==> centos8: Machine booted and ready!
==> centos8: Checking for guest additions in VM...
==> centos8: Setting hostname...
==> centos8: Configuring and enabling network interfaces...
==> centos8: Mounting shared folders...
    centos8: /vagrant => C:/vagrant/centos8
```
## test vagrant box
shared folder mounted properly,
```
[vagrant@centos8 ~]$ df -h
Filesystem           Size  Used Avail Use% Mounted on
devtmpfs             393M     0  393M   0% /dev
tmpfs                410M     0  410M   0% /dev/shm
tmpfs                410M  5.6M  404M   2% /run
tmpfs                410M     0  410M   0% /sys/fs/cgroup
/dev/mapper/cl-root   47G  2.5G   45G   6% /
/dev/sda1            976M  142M  767M  16% /boot
vagrant              476G  397G   79G  84% /vagrant
tmpfs                 82M     0   82M   0% /run/user/1000
[vagrant@centos8 ~]$ ll /vagrant/
total 1
-rwxrwxrwx. 1 vagrant vagrant 490 Aug 27 09:35 Vagrantfile
[vagrant@centos8 ~]$ mount |grep vagrant
vagrant on /vagrant type vboxsf (rw,nodev,relatime,iocharset=utf8,uid=1000,gid=1000)
```
NIC and Internet access,
```
[vagrant@centos8 ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:09:18:d2 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic noprefixroute enp0s3
       valid_lft 86176sec preferred_lft 86176sec
    inet6 fe80::a00:27ff:fe09:18d2/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:72:1c:05 brd ff:ff:ff:ff:ff:ff
    inet 192.168.99.20/24 brd 192.168.99.255 scope global noprefixroute enp0s8
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe72:1c05/64 scope link
       valid_lft forever preferred_lft forever

[vagrant@centos8 ~]$ ip r
default via 10.0.2.2 dev enp0s3 proto dhcp metric 100
10.0.2.0/24 dev enp0s3 proto kernel scope link src 10.0.2.15 metric 100
192.168.99.0/24 dev enp0s8 proto kernel scope link src 192.168.99.20 metric 101

[vagrant@centos8 ~]$ ping -c 2 google.ca
PING google.ca (216.58.194.131) 56(84) bytes of data.
64 bytes from dfw06s49-in-f3.1e100.net (216.58.194.131): icmp_seq=1 ttl=98 time=148 ms
64 bytes from dfw06s49-in-f3.1e100.net (216.58.194.131): icmp_seq=2 ttl=103 time=62.3 ms
```
