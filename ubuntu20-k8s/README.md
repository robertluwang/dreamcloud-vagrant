# Launch Ubuntu 20.04 k8s 1.21.8 cluster using vagrant box

[dreamcloud/ubuntu20-k8s](https://app.vagrantup.com/dreamcloud/boxes/ubuntu20-k8s) is a k8s dev ready box, here is demo to show how to launch a 3 nodes k8s cluster in few mins using vagrant.

## tool set
- Vagrant 2.2.10
- Virtualbox 6.1

## prepare Vagrantfile

```
$ mkdir /mnt/c/vagrant/ub20k8s
$ curl -LO https://raw.githubusercontent.com/robertluwang/dreamcloud-vagrant/master/ubuntu20-k8s/Vagrantfile
```
assume the k8s cluster setting:

- k8s-master 192.168.22.23 CPUx2 RAM 4G 
- k8s-node1   192.168.22.24 CPUx2 RAM 2G
- k8s-node2   192.168.22.25 CPUx2 RAM 2G
- pod network: calico 

## launch k8s cluster from vagrant box 
```
/mnt/c/vagrant/ub20k8s$ vagrant.exe up
```
```
/mnt/c/vagrant/ub20k8s$ vagrant.exe status
Current machine states:

k8s-master                running (virtualbox)
k8s-node1                  running (virtualbox)
k8s-node2                  running (virtualbox)
```

## k8s cluster is ready 
```
vagrant@k8s-master:~$ kubectl get nodes
NAME         STATUS   ROLES    AGE   VERSION
k8s-master   Ready    master   50m   v1.21.0
k8s-node1     Ready    <none>   49m   v1.21.0
k8s-node2     Ready    <none>   49m   v1.21.0

vagrant@k8s-node1:~$ kubectl get nodes
NAME         STATUS   ROLES    AGE   VERSION
k8s-master   Ready    master   81m   v1.19.0
k8s-node1     Ready    <none>   79m   v1.19.0
k8s-node2     Ready    <none>   49m   v1.21.0
```
## k8s health check 
```
systemctl status kubelet
kubeadm config print init-defaults
kubectl config view
kubectl describe node k8s-master
kubectl get nodes -o wide
kubectl get pods --all-namespaces
```
## common issue and remedy 
### vagrant NIC 
There are two NICs used in vagrant:
- NAT for internet access, default is 10.0.2.15
- Host-only for internal network, 192.168.22.0/24 

By default kubeadm always picked up NAT ip as etcd interface, however all vagrant vm has same ip and cannot talk each other using NAT.

[certs] etcd/peer serving cert is signed for DNS names [localhost k8s-master] and IPs [10.0.2.15 127.0.0.1 ::1]

As remedy, need to use option --apiserver-advertise-address
```
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.22.23 \
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
The token is for 2 hours, since I launch k8s cluster from Vagrantfile for few test nodes in lab, assume whole setup work will be done less than 2 hours, so I just save token as log file on master and fetch from worker then run it, it is fair enough for dev lab.
```
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant  k8s-master:/tmp/kubeadm.log  /tmp/kubeadm.log
token=`cat /tmp/kubeadm.log |grep "kubeadm join"|head -1 |awk -Ftoken '{print $2}'|awk '{print $1}'`
certhash=`cat /tmp/kubeadm.log |grep discovery-token-ca-cert-hash|tail -1|awk '{print $2}'`

sudo kubeadm join k8s-master:6443 --token $token \
  --discovery-token-ca-cert-hash $certhash 
```
### cli completion 
```
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
echo "export do='--dry-run=client -o yaml'" >>~/.bashrc
