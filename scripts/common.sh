#! /bin/bash

# Variable Declaration

KUBERNETES_VERSION="1.22.6-00"

# disable swap 
sudo swapoff -a
# keeps the swaf off during reboot
# sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo sed -i 's/\/swap/#swap/' /etc/fstab
#############
echo quit | openssl s_client -showcerts -servername packages.cloud.google.com -connect www.naver.com:443 > kube.crt

#sed -ni '73,99p' kube.crt
#find second certifcate startline and endline  and cut between of them to make kube.crt
SLINE=$(grep -n BEGIN kube.crt | cut -d: -f1 | tail -1)
ELINE=$(grep -n END kube.crt | cut -d: -f1 | tail -1)
sed -ni "$SLINE"','"$ELINE"'p' kube.crt

sudo cp kube.crt /usr/local/share/ca-certificates/kube.crt
sudo update-ca-certificates
#############
sudo apt-get update -y
sudo apt-get install -y \
     apt-transport-https \
     ca-certificates \
     curl \
     gnupg \
     lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo apt install docker.io curl lsg-release -y

# Following configurations are recomended in the kubenetes documentation for Docker runtime. Please refer https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker

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
sudo usermod -aG docker vagrant
echo "Docker Runtime Configured Successfully"


sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y

sudo apt-get install -y kubelet=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION

sudo apt-mark hold kubelet kubeadm kubectl
