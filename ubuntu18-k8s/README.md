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
## trick and tips 
### vagrant NIC 
There are two NICs used in vagrant:
- NAT for internet access, default is 10.0.2.15
- Host-only for internal network, 192.168.20.0/24 

By default kubeadm always picked up NAT ip as etcd interface, however all vagrant vm has same ip and cannot talk each other using NAT.

[certs] etcd/peer serving cert is signed for DNS names [localhost k8s-master] and IPs [10.0.2.15 127.0.0.1 ::1]

As remedy, need to use option --apiserver-advertise-address
```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.20.23 \
 | tee /tmp/kubeadm.log 
```
### cannot run kubectl on worker node
```
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```
The issue is lack of env setting on worker, which is from admin.config but it only generated when "kubeadm init" on master, so need to transfer to each worker and setup similar as on master, 
```
mkdir -p $HOME/.kube 
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config                                         
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
this is what I did, 
```
mkdir -p $HOME/.kube 
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant k8s-master:$HOME/.kube/config $HOME/.kube/config                                       
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
### kubeadm join on worker
The token is for 2 hours, since I launch k8s cluster from Vagrantfile for few test nodes in lab, so assume whole work will be done less than 2 hours, so I just save token from master to log and transfer to worker then run it.
```
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant  k8s-master:/tmp/kubeadm.log  /tmp/kubeadm.log
token=`cat /tmp/kubeadm.log |grep "kubeadm join"|head -1 |awk -Ftoken '{print $2}'|awk '{print $1}'`
certhash=`cat /tmp/kubeadm.log |grep discovery-token-ca-cert-hash|tail -1|awk '{print $2}'`

sudo kubeadm join k8s-master:6443 --token $token \
  --discovery-token-ca-cert-hash $certhash 
```


