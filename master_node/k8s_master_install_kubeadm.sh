#!/bin/bash

set -x
echo "Start master node requirements installation..."

# Install Docker
# Check if Docker is installed on the system
if ! [ -x "$(command -v docker)" ]; then
    # If not, install it
    sudo apt-get update
    sudo apt-get install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --batch --yes

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
fi

# check if golang is installed

if [ $(dpkg-query -W -f='${Status}' golang 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
    # install golang
    wget https://storage.googleapis.com/golang/getgo/installer_linux
    chmod +x ./installer_linux
    ./installer_linux
    source ~/.bash_profile
fi

# 2.2 Enable cri-docker service (probably with sudo)
git clone https://github.com/Mirantis/cri-dockerd.git

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket

# 3. Install kubeadm
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Check if kubeadm, kubectl, kubelet are installed
kubeadm_installed=$(dpkg -s kubeadm | grep "Status")
kubectl_installed=$(dpkg -s kubectl | grep "Status")
kubelet_installed=$(dpkg -s kubelet | grep "Status")

# If not installed, install
if [[ $kubeadm_installed == "Status: install ok installed" ]]; then
    echo "Kubeadm is already installed."
else
    echo "Installing Kubeadm..."
    sudo apt-get update && sudo apt-get install -y kubeadm
fi

if [[ $kubectl_installed == "Status: install ok installed" ]]; then
    echo "Kubectl is already installed."
else
    echo "Installing Kubectl..."
    sudo apt-get update && sudo apt-get install -y kubectl
fi

if [[ $kubelet_installed == "Status: install ok installed" ]]; then
    echo "Kubelet is already installed."
else
    echo "Installing Kubelet..."
    sudo apt-get update && sudo apt-get install -y kubelet
fi
sudo apt-mark hold kubelet kubeadm kubectl

# 4. Setup network cidr

# Check if kubeadm is already initialized
if [ "$(kubeadm init --dry-run 2>&1 | grep 'already initialized')" ]; then
    echo "kubeadm is already initialized"
else
    sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/cri-dockerd.sock
fi

# 5. Start using cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 6. Install calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/tigera-operator.yaml
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml

