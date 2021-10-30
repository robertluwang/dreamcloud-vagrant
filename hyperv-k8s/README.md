## Build k8s cluster on hyper-v with Vagrant 
Demo how to build up multi nodes k8s cluster on hyper-v with Vagrant.

Will address few pain points:

- NAT static ip adaptor in hyper-v, needed for permanent k8s API server
- reset static ip in vagrant provision before installation and configuration

## Docker installation script

Following up Docker official Ubuntu installation procedure, [https://docs.docker.com/engine/install/](https://docs.docker.com/engine/install/).

Run below `docker-install.sh` to install docker server, client and enable cgroupdriver to systemd.

```bash
echo === $(date) Provisioning - docker-install.sh by $(whoami) start

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER

# turn off swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

echo === $(date) Provisioning - docker-install.sh by $(whoami) end
```

## k8s installation script

Following up k8s kubeadm installation guide, run below `k8s-install.sh` to quickly install kubeadm, kubectl and kubelet latest packages.

[https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

```bash
echo === $(date) Provisioning - k8s-install.sh by $(whoami) start

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# cli completion
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
echo "export do='--dry-run=client -o yaml'" >>~/.bashrc

echo === $(date) Provisioning - k8s-install.sh $1 by $(whoami) end
```

## k8s cluster init script

Assume we use calico network plugin for k8s cluster, skip cpu and memory check for test.

After kubeadm init success, saves the token info to /tmp/kubeadm.log, to quickly join worker node to cluster later.

Put all in handy script `k8s-init.sh`  for cluster init.

```bash
echo === $(date) Provisioning - k8s-init.sh $1 by $(whoami) start

if [ -z "$1" ];then
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
else
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$1 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
fi

# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install calico network addon
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# allow run on master
kubectl taint nodes --all node-role.kubernetes.io/master-

echo === $(date) Provisioning - k8s-init.sh $1 by $(whoami) end
```

## k8s cluster reset script

Apply below handy script `k8s-reset.sh` to reset cluster when whatever reason cluster mess up.

```bash
echo === $(date) Provisioning - k8s-reset.sh $1 by $(whoami) start

sudo kubeadm reset -f
date
if [ -z "$1" ];then
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
else
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$1 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
fi
# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install calico network addon
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# allow run on master
kubectl taint nodes --all node-role.kubernetes.io/master-

echo === $(date) Provisioning - k8s-reset.sh $1 by $(whoami) end
```

## k8s worker join script

It is lazy way to get join token if worker join soon after cluster init by copying kubeadm init log from master, it is fair enough for dev test purpose.

We need to tell master ip $1 to join script, `k8s-join.sh`

```bash
echo === $(date) Provisioning - k8s-join.sh $1 by $(whoami) start

sudo sed -i '/master/d' /etc/hosts
sudo sed -i "1i$1 master" /etc/hosts

# add private key 
curl -Lo $HOME/.ssh/vagrant https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant
chmod 0600 $HOME/.ssh/vagrant

# join cluster
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:/tmp/kubeadm.log  /tmp/kubeadm.log
token=`cat /tmp/kubeadm.log |grep "kubeadm join"|head -1 |awk -Ftoken '{print $2}'|awk '{print $1}'`
certhash=`cat /tmp/kubeadm.log |grep discovery-token-ca-cert-hash|tail -1|awk '{print $2}'`

sudo kubeadm join master:6443 --token $token \
  --discovery-token-ca-cert-hash $certhash

# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:$HOME/.kube/config $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo === $(date) Provisioning - k8s-join.sh $1 by $(whoami) end
```

## k8s worker rejoin script

need to reset kubeadm config when mess up before join to cluster, otherwise has similar error as below,

```bash
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR FileAvailable--etc-kubernetes-kubelet.conf]: /etc/kubernetes/kubelet.conf already exists
        [ERROR Port-10250]: Port 10250 is in use
        [ERROR FileAvailable--etc-kubernetes-pki-ca.crt]: /etc/kubernetes/pki/ca.crt already exists
```

run `k8s-rejoin.sh` to reset kubeadm and join to cluster on worker node,

```bash
echo === $(date) Provisioning - k8s-rejoin.sh $1 by $(whoami) start

sudo sed -i '/master/d' /etc/hosts
sudo sed -i '1i$1 master' /etc/hosts

sudo kubeadm reset -f

# join cluster
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:/tmp/kubeadm.log  /tmp/kubeadm.log
token=`cat /tmp/kubeadm.log |grep "kubeadm join"|head -1 |awk -Ftoken '{print $2}'|awk '{print $1}'`
certhash=`cat /tmp/kubeadm.log |grep discovery-token-ca-cert-hash|tail -1|awk '{print $2}'`

sudo kubeadm join master:6443 --token $token \
  --discovery-token-ca-cert-hash $certhash

# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:$HOME/.kube/config $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo === $(date) Provisioning - k8s-rejoin.sh $1 by $(whoami) end
```

## setup NAT static ip for hyper-v in vagrant

first for all, create own NAT virtual switch on host Powershell,

```bash
New-VMSwitch -SwitchName "NAT" -SwitchType Internal
New-NetIPAddress -IPAddress 192.168.120.1 -PrefixLength 24 -InterfaceAlias 'vEthernet (NAT)'
New-NetNat -Name netNAT -InternalIPInterfaceAddressPrefix 192.168.120.0/24
```

Vagrant not supports well for hyper-v network, have to choice hyper-v virtual switch and setup static ip, routing by own for NAT, here is example of Vagrantfile,

```bash
$nic = <<SCRIPT
echo === $(date) Provisioning - nic $1 by $(whoami) start  

cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [$1/24]
      gateway4: 192.168.120.1
      nameservers:
        addresses: [4.2.2.1, 4.2.2.2, 208.67.220.220]
EOF

cat /etc/netplan/01-netcfg.yaml

sudo netplan apply

echo eth0 setting

ip addr
ip route
ping -c 2 google.ca

echo === $(date) Provisioning - nic $1 by $(whoami) end

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu1804"
  config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.provider "hyperv" do |v|
          v.vmname="master"
          v.memory=2048
          v.cpus=1
      end
      master.vm.provision "shell", inline: $nic, args: "192.168.120.2", privileged: false
  end
  config.vm.define "worker" do |worker|
      worker.vm.hostname = "worker"
      worker.vm.provider "hyperv" do |v|
          v.vmname="worker"
          v.memory=1024
          v.cpus=1
      end
      worker.vm.provision "shell", inline: $nic, args: "192.168.120.3", privileged: false
  end
end
```

## cluster test

hyper-v vm can communicate each other and to/from Host, also access to Internet

```bash
PS C:\Users\oldhorse\vagrant\master> vagrant ssh master
vagrant@master:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:c3:82:1e brd ff:ff:ff:ff:ff:ff
    inet 192.168.120.2/24 brd 192.168.120.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fec3:821e/64 scope link
       valid_lft forever preferred_lft forever
vagrant@master:~$ ping 192.168.120.3
PING 192.168.120.3 (192.168.120.3) 56(84) bytes of data.
64 bytes from 192.168.120.3: icmp_seq=1 ttl=64 time=1.72 ms
64 bytes from 192.168.120.3: icmp_seq=2 ttl=64 time=0.685 ms
^C
--- 192.168.120.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.685/1.205/1.725/0.520 ms
vagrant@master:~$ ping google.ca
PING google.ca (172.217.1.195) 56(84) bytes of data.
64 bytes from 172.217.1.195: icmp_seq=1 ttl=127 time=31.3 ms
64 bytes from 172.217.1.195: icmp_seq=2 ttl=127 time=29.7 ms
64 bytes from 172.217.1.195: icmp_seq=3 ttl=127 time=27.5 ms

vagrant@worker:~$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:15:5d:c3:82:1f brd ff:ff:ff:ff:ff:ff
    inet 192.168.120.3/24 brd 192.168.120.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::215:5dff:fec3:821f/64 scope link
       valid_lft forever preferred_lft forever
vagrant@worker:~$ ip route
default via 192.168.120.1 dev eth0 proto static
192.168.120.0/24 dev eth0 proto kernel scope link src 192.168.120.3
vagrant@worker:~$ ping 192.168.120.2
PING 192.168.120.2 (192.168.120.2) 56(84) bytes of data.
64 bytes from 192.168.120.2: icmp_seq=1 ttl=64 time=0.681 ms
^C
--- 192.168.120.2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.681/0.681/0.681/0.000 ms
vagrant@worker:~$ ping 192.168.120.1
PING 192.168.120.1 (192.168.120.1) 56(84) bytes of data.
64 bytes from 192.168.120.1: icmp_seq=1 ttl=128 time=0.529 ms
64 bytes from 192.168.120.1: icmp_seq=2 ttl=128 time=0.430 ms
^C
--- 192.168.120.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1015ms
rtt min/avg/max/mdev = 0.430/0.479/0.529/0.054 ms
vagrant@worker:~$ ping google.ca
PING google.ca (142.251.45.99) 56(84) bytes of data.
64 bytes from 142.251.45.99: icmp_seq=1 ttl=127 time=31.6 ms
64 bytes from 142.251.45.99: icmp_seq=2 ttl=127 time=94.4 ms
64 bytes from 142.251.45.99: icmp_seq=3 ttl=127 time=31.8 ms
```

## full k8s cluster with vagrant

We put all together in final Vagrantfile, 

```bash
$nic = <<SCRIPT

echo === $(date) Provisioning - nic $1 by $(whoami) start  

cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      dhcp6: no
      addresses: [$1/24]
      gateway4: 192.168.120.1
      nameservers:
        addresses: [4.2.2.1, 4.2.2.2, 208.67.220.220]
EOF

cat /etc/netplan/01-netcfg.yaml

sudo netplan apply

echo eth0 setting

ip addr
ip route
ping -c 2 google.ca

echo === $(date) Provisioning - nic $1 by $(whoami) end

SCRIPT

$dockerInstall = <<SCRIPT

echo === $(date) Provisioning - dockerInstall by $(whoami) start

sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo groupadd docker
sudo usermod -aG docker $USER

# turn off swap
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

echo === $(date) Provisioning - dockerInstall by $(whoami) end

SCRIPT

$k8sInstall = <<SCRIPT

echo === $(date) Provisioning - k8sInstall by $(whoami) start

sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# cli completion
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc
echo "export do='--dry-run=client -o yaml'" >>~/.bashrc

echo === $(date) Provisioning - k8sInstall by $(whoami) end

SCRIPT

$k8sInit = <<SCRIPT

# $1 - master/api server ip 

echo === $(date) Provisioning - k8sInit $1 by $(whoami) start

if [ -z "$1" ];then
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
else
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$1 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem | tee /tmp/kubeadm.log
fi

# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install calico network addon
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

# allow run on master
kubectl taint nodes --all node-role.kubernetes.io/master-

echo === $(date) Provisioning - k8sInit $1 by $(whoami) end

SCRIPT

$k8sJoin = <<SCRIPT
# $1 - master/api server ip

echo === $(date) Provisioning - k8sJoin $1 by $(whoami) start

sudo sed -i '/master/d' /etc/hosts
sudo sed -i "1i$1 master" /etc/hosts

# add private key 
curl -Lo $HOME/.ssh/vagrant https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant
chmod 0600 $HOME/.ssh/vagrant

# join cluster
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:/tmp/kubeadm.log  /tmp/kubeadm.log
token=`cat /tmp/kubeadm.log |grep "kubeadm join"|head -1 |awk -Ftoken '{print $2}'|awk '{print $1}'`
certhash=`cat /tmp/kubeadm.log |grep discovery-token-ca-cert-hash|tail -1|awk '{print $2}'`

sudo kubeadm join master:6443 --token $token \
  --discovery-token-ca-cert-hash $certhash

# allow normal user to run kubectl
if [ -d $HOME/.kube ]; then
  rm -r $HOME/.kube
fi
mkdir -p $HOME/.kube
scp -q -o "StrictHostKeyChecking no" -i $HOME/.ssh/vagrant master:$HOME/.kube/config $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo === $(date) Provisioning - k8sJoin $1 by $(whoami) end

SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu1804"
  config.ssh.insert_key = false
  config.vm.box_check_update = false

  config.vm.define "master" do |master|
      master.vm.hostname = "master"
      master.vm.provider "hyperv" do |v|
          v.vmname = "master"
          v.memory = 2048
          v.cpus = 1
      end
      master.vm.provision "shell", inline: $nic, args: "192.168.120.2", privileged: false
      master.vm.provision "shell", inline: $dockerInstall, privileged: false
      master.vm.provision "shell", inline: $k8sInstall, privileged: false
      master.vm.provision "shell", inline: $k8sInit, args: "192.168.120.2", privileged: false
  end
  config.vm.define "worker" do |worker|
      worker.vm.hostname = "worker"
      worker.vm.provider "hyperv" do |v|
          v.vmname = "worker"
          v.memory = 1024
          v.cpus = 1
      end
      worker.vm.provision "shell", inline: $nic, args: "192.168.120.3", privileged: false
      worker.vm.provision "shell", inline: $dockerInstall, privileged: false
      worker.vm.provision "shell", inline: $k8sInstall, privileged: false
      worker.vm.provision "shell", inline: $k8sJoin, args: "192.168.120.2", privileged: false
  end
end
```

## k8s cluster test

```bash
vagrant@master:~$ k cluster-info
Kubernetes control plane is running at https://192.168.120.2:6443
CoreDNS is running at https://192.168.120.2:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
vagrant@master:~$
vagrant@master:~$ k run test --image=nginx
pod/test created
vagrant@master:~$ k get po
NAME   READY   STATUS              RESTARTS   AGE
test   0/1     ContainerCreating   0          3s

vagrant@master:~$ k describe pod test
Name:         test
Namespace:    default
Priority:     0
Node:         worker/192.168.120.3
Start Time:   Sat, 30 Oct 2021 14:29:57 +0000
Labels:       run=test
Annotations:  cni.projectcalico.org/containerID: 177f5a3b56ed4a0e499956247b078712b4e7fa57e5cae1e67270e6e7c7aaf7dd
              cni.projectcalico.org/podIP: 192.168.171.65/32
              cni.projectcalico.org/podIPs: 192.168.171.65/32
Status:       Running
IP:           192.168.171.65
IPs:
  IP:  192.168.171.65
Containers:
  test:
    Container ID:   docker://f76551b24d4cc2cb96788b4737df50f8431b5fc0efaaacfa521b136e03250c21
    Image:          nginx
    Image ID:       docker-pullable://nginx@sha256:644a70516a26004c97d0d85c7fe1d0c3a67ea8ab7ddf4aff193d9f301670cf36
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Sat, 30 Oct 2021 14:30:21 +0000
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-dwxcw (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  kube-api-access-dwxcw:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m4s   default-scheduler  Successfully assigned default/test to worker
  Normal  Pulling    3m3s   kubelet            Pulling image "nginx"
  Normal  Pulled     2m40s  kubelet            Successfully pulled image "nginx" in 22.319837942s
  Normal  Created    2m40s  kubelet            Created container test
  Normal  Started    2m40s  kubelet            Started container test
vagrant@master:~$ k get  po
NAME   READY   STATUS    RESTARTS   AGE
test   1/1     Running   0          3m8s

vagrant@master:~$ curl 192.168.171.65
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## common issues

kubeadm error

```bash
+ sudo kubeadm init --pod-network-cidr=192.168.0.0/16
[init] Using Kubernetes version: v1.22.2
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
        [ERROR Mem]: the system RAM (1255 MB) is less than the minimum 1700 MB
        [ERROR Swap]: running with swap on is not supported. Please disable swap
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```

For test purpose, you can skip memory and cpu requirement warning, 

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem
```
