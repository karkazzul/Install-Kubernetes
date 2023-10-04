# Installation de Kubernetes

## 0) Documentation officiel

Lien vers la **[documentation de Kubernetes](https://kubernetes.io/fr/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)**

## 1)  Prérequis: 
    - 3 serveurs fonctionnels
    - Accès à internet
    - Communication entre les serveurs
    - Serveurs sous debian et à jours
## 2) Désactivation du swapp

```shell
swapoff -a                 # Disable all devices marked as swap in /etc/fstab
sed -e '/swap/ s/^#*/#/' -i /etc/fstab   # Comment the correct mounting point
systemctl mask swap.target               # Completely disabled
```

## 3) Installation de containerd en tant que runtime 

- Lien vers la [documentation](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd)

- Exécuter le script **install.sh** pour installer et configurer containerd. 

## 4) Configuration de containerd

- Editer le fichier **/etc/containerd/config.toml**:
```bash
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
  ...
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
    SystemdCgroup = true
```
- Redémarrer le service containerd:
```bash
sudo systemctl restart containerd
```

## 5) Installation de kubeadm, kubelet et kubectl

- Lister les versions disponible de  kubernetes: 
```shell
apt-cache policy kubelet
```
- Installer les 3 outils avec la version choisie: 
```shell
apt-get install -y kubelet=1.XX.X-XX kubeadm=1.XX.X-XX kubectl=1.XX.X-XX
```
- Figer les paquets : `apt-mark hold kubelet kubeadm kubectl`

## 6) Initalisation du master

- Taper la commande suivante initialiser le master
```bash
kubeadm init --pod-network-cidr=192.168.0.0/16 --kubernetes-version 1.XX.X
```
## 7) Paramétrage de kubectl

- Taper ces commandes pour pouvoir utiliser kubectl:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
- Activation de l'autocomplétion + génération d'alias:
```bash
echo 'source <(kubectl completion bash)' >>~/.bashrc
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
```

## 8) Installation et configuration d'un add-on réseau
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises => manifest
- Télécharger le fichier yaml du plugin de calico:
```bash
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml -O
```
- Décommenter les lignes:
```bash
- name: CALICO_IPV4POOL_CIDR
  value: "192.168.0.0/16"
```
- Appliquer le fichier de configuration de calico:
```bash
kubectl apply -f calico.yaml
```
- Check, si les pods de calico sont en état **running** avec la commande `kubectl get pods -A`

**Si les pods ne sont pas en `running`, ne pas continuer !!!!!**

## 9) Faire rejoindre les noeuds

- Sur les noeuds, taper le résultat de la commande `kubeadm token create --print-join-command`