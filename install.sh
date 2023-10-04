#!/bin/bash

set -euxo pipefail

cat <<EOF |   tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

   modprobe overlay
   modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF |    tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
   sysctl --system

# Install containerd
## Set up the repository
### Install packages to allow apt to use a repository over HTTPS
   apt-get update
   apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

### Add Docker’s official GPG key
    mkdir -p /etc/apt/keyrings
 curl -fsSL https://download.docker.com/linux/debian/gpg |    gpg --dearmor -o /etc/apt/keyrings/docker.gpg

### Add Docker apt repository.
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" |    tee /etc/apt/sources.list.d/docker.list > /dev/null

### Add Kuberntes apt repository

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

## Install containerd
   apt-get update
   apt-get install -y containerd.io

# Configure containerd
   mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml

# Restart containerd
   systemctl restart containerd
