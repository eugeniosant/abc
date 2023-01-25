# Playbook to run on k3s Entando Redi and Solr

Prerequisite:
- hub-tool
  https://github.com/docker/hub-tool/releases

- ansible
  eg. on Ubuntu
  
sudo apt install software-properties-common 

sudo apt-add-repository --yes --update ppa:ansible/ansible 

sudo apt install ansible

- k3s or k3d

# How to start the playbook

- login to docker-hub using hub-tool

hub-tool login

- Clone the repo
git clone entando/entando_redis_solr_k3s_automation.git

cd entando_redis_solr_k3s_automation

sudo ansible-playbook -i inventory main.yaml
