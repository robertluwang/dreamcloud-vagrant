
# build up ubuntu openstack vm node using vagrant

## launch ubuntu vm node 
download Vagrantfile, 
```
mkdir -p vagrant/ubopenstack
cd vagrant/ubopenstack
curl -LO https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ubopenstack/Vagrantfile
```
launch ubuntu vm node:
- hostname: ubopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.110.0.16
```
vagrant up
vagrant ssh
```
you can install openstack using devstack as test.

## launch ubuntu openstack vm node with external script
download Vagrantfile, 
```
mkdir -p vagrant/ubopenstack
cd vagrant/ubopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ubopenstack/Vagrantfile.devstack
```
launch ubuntu openstack vm node with external script:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.110.0.16
```
vagrant up
vagrant ssh
```
the ubuntu openstack vm node ready for you.

## launch ubuntu openstack vm node using ub17os box with inline ip update script 
download Vagrantfile, 
```
mkdir -p vagrant/ubopenstack
cd vagrant/ubopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ubopenstack/Vagrantfile.ub17os
```
launch ubuntu openstack vm node with external script:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.110.0.16
```
vagrant up
vagrant ssh
```
the ubuntu openstack vm node ready for you.

## launch ubuntu openstack vm node using ub17os box with external ip update script 
download Vagrantfile, 
```
mkdir -p vagrant/ubopenstack
cd vagrant/ubopenstack
curl -Lo Vagrantfile https://raw.githubusercontent.com/robertluwang/cloud-hands-on-guide/master/dc-vagrant-cloud/ubopenstack/Vagrantfile.ub17osbox
```
launch ubuntu openstack vm node with external script:
- hostname: ctopenstack
- memory: 6GB
- cpu: 2
- 1st NIC: NAT
- 2nd NIC: hostonly private network  10.110.0.16
```
vagrant up
vagrant ssh
```
the ubuntu openstack vm node ready for you.
