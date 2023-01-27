# kubeadm_setup
This is k8s cluster setup with kubeadm
Installation:
1. Install Docker
2. Install and enable cri-docker service 
3. Install kubeadm, kubectl, kubelet

For master node:

4. Init kubeadm
5. Install and run calico 

For worker node:

4. Join master node with token using command:
sudo kubeadm join $K8S_MASTER_IP:$K8S_MASTER_PORT --token $TOKEN --discovery-token-ca-cert-hash sha256:$HASH --cri-socket=unix:///var/run/cri-dockerd.sock
