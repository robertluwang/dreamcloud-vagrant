# launch k8s 1.19 cluster using vagrant box dreamcloud-ubuntu18-k8s

[dreamcloud/ubuntu18-k8s](https://app.vagrantup.com/dreamcloud/boxes/ubuntu18-k8s) is a k8s dev ready box, here is demo to show how to launch a 2 nodes k8s cluster in few mins using vagrant.

## tool set
- Vagrant 2.2.10
- Virtualbox 6.1
- WSL 

## prepare Vagrantfile

```
$ mkdir /mnt/c/vagrant/ub18k8s
$ curl -LO https://raw.githubusercontent.com/robertluwang/dreamcloud-vagrant/master/ubuntu18-k8s/Vagrantfile
```
assume the k8s cluster setting:

- k8s-master 192.168.20.23 CPUx2 RAM 4G 
- k8s-node   192.168.20.24 CPUx2 RAM 2G
- pod network: calico 

## launch k8s cluster from vagrant box 
```
/mnt/c/vagrant/ub18k8s$ vagrant.exe up
```
```
/mnt/c/vagrant/ub18k8s$ vagrant.exe status
Current machine states:

k8s-master                running (virtualbox)
k8s-node                  running (virtualbox)
```

## k8s cluster is ready 
```
vagrant@k8s-master:~$ kubectl get nodes
NAME         STATUS   ROLES    AGE   VERSION
k8s-master   Ready    master   50m   v1.19.0
k8s-node     Ready    <none>   49m   v1.19.0

vagrant@k8s-node:~$ kubectl get nodes
NAME         STATUS   ROLES    AGE   VERSION
k8s-master   Ready    master   81m   v1.19.0
k8s-node     Ready    <none>   79m   v1.19.0
```

