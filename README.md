# Playbook to run on k3s Entando Redi and Solr

Prerequisite:

- ansible
  eg. on Ubuntu
  
sudo apt install software-properties-common 

sudo apt-add-repository --yes --update ppa:ansible/ansible 

sudo apt install ansible

- k3s or k3d

  copy as sudoers kubeconfig file in the user home-dir
  
  mkdir /home/"user"/.kube
  
  cp /etc/rancher/k3s/k3s.yaml /home/"user"/config

  Verify to be able to connect to the cluster as user

  export KUBECONFIG=/home/"user"/.kube/config
  
  kubectl get nodes

- helm

  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh

# How to start the playbook

- Clone the repo

  git clone entando/entando_redis_solr_k3s_automation.git

  cd entando_redis_solr_k3s_automation

- Download the namespace-resource file for a specific Entando version in the main project folder:

  wget https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v{{ entando_version }}/manifests/k8s-116-and-later/namespace-scoped-deployment/namespace-resources.yaml
  
  eg.
  wget https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v7.1.3/manifests/k8s-116-and-later/namespace-scoped-deployment/namespace-resources.yaml

  modify images tags as required

- retrive the ingress ip-adress of you ingress controller

  eg.
  kubectl get svc -A |grep LoadBalancer

  user@home:~$ sudo kubectl get svc -A |grep LoadBalancer
kube-system   traefik  LoadBalancer   10.43.169.185   192.168.176.2,192.168.176.3   80:30264/TCP,443:32685/TCP 12m

In this case I'm piking up the address 192.168.176.2 that I'm going to use later

- Run the playook specifying the following variables

  eg.
  ansible-playbook custom_main.yaml --extra-vars="namespace=entando appname=test_redis entver=7.1.3 ingress=192.178.176.2 username=ubuntu"
