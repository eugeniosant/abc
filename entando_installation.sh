#!/bin/bash
#  Author
#  Sergio Molino
#
#  This script install Entando application Redis and Solr on k3s/k3d
#
namespace=$1
appname=$2

if [[ -z "$namespace" ]]; then
        echo "Use "$(basename "$0")" NAMESPACE";
        exit 1;
fi
if [[ -z "$appname" ]]; then
        echo "Use "$(basename "$0")" APPNAME";
        exit 1;
fi

echo "##################################################################################"
echo "##################################################################################"
echo "Install Redis cluster"
echo "##################################################################################"
echo "##################################################################################"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis --values values.yaml

sleep 200
echo "##################################################################################"
echo "##################################################################################"

echo "##################################################################################"
echo "##################################################################################"
echo " Install helm repo and Solr Instances "
echo "##################################################################################"
echo "##################################################################################"
helm repo add apache-solr https://solr.apache.org/charts
helm repo update
echo "##################################################################################"
echo "##################################################################################"

echo "##################################################################################"
echo "##################################################################################"
echo " Install the Solr & Zookeeper CRDs"
echo "##################################################################################"
echo "##################################################################################"
kubectl create -f https://solr.apache.org/operator/downloads/crds/v0.5.0/all-with-dependencies.yaml

echo "##################################################################################"
echo "##################################################################################"
echo " Install the Solr operator and Zookeeper Operator"
echo "##################################################################################"
echo "##################################################################################"
helm install solr-operator apache-solr/solr-operator --version 0.5.0
echo "##################################################################################"
echo "##################################################################################"
kubectl get svc -A | grep LoadBalancer | awk '{sub(/,.*/,""); print $5}' | while read HOST;do
echo -e "
apiVersion: solr.apache.org/v1beta1
kind: SolrCloud
metadata:
  name: solr
spec:
  solrAddressability:
    external:
      domainName: $HOST.nip.io
      method: Ingress
      useExternalAddress: true
  customSolrKubeOptions:
    podOptions:
      resources:
        limits:
          memory: 3Gi
          cpu: 2000m
        requests:
          cpu: 700m
          memory: 3Gi
  dataStorage:
    persistent:
      pvcTemplate:
        spec:
          resources:
            requests:
              storage: 20Gi
      reclaimPolicy: Delete
  replicas: 3
  solrImage:
    repository: entando/entando-solr
    tag: '8'
  solrJavaMem: -Xms2048M -Xmx2048M
  updateStrategy:
    method: StatefulSet
  zookeeperRef:
    provided:
      chroot: /explore
      image:
        pullPolicy: IfNotPresent
        repository: pravega/zookeeper
        tag: 0.2.13
      persistence:
        reclaimPolicy: Delete
        spec:
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 2Gi
      replicas: 3
      zookeeperPodPolicy:
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 250m
            memory: 500Mi" | kubectl apply -f -; done

sleep 250
echo "##################################################################################"
echo "##################################################################################"
echo " Add entando document type on solr"
echo "##################################################################################"
echo "##################################################################################"
kubectl get svc -A | grep LoadBalancer | awk '{sub(/,.*/,""); print $5}' | while read HOST;do
curl "http://default-solr-solrcloud.$HOST.nip.io/solr/admin/collections?action=CREATE&name=entando&numShards=1&replicationFactor=3&maxShardsPerNode=2&collection.configName=_default"; done

echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Creating Namespace $namespace"
echo ""
echo "##################################################################################"
echo "##################################################################################"
kubectl create namespace $namespace

echo ""
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Creating Cluster Resources"
echo ""
echo "##################################################################################"
echo "##################################################################################"

kubectl apply -f https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v7.1.3/manifests/k8s-116-and-later/namespace-scoped-deployment/cluster-resources.yaml

#kubectl apply -n $namespace -f https://raw.githubusercontent.com/entando-k8s/entando-k8s-operator-bundle/v7.1.3/manifests/k8s-116-and-later/namespace-scoped-deployment/namespace-resources.yaml
kubectl apply -n $namespace -f namespace-resources_custom.yaml
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Deploying Applicaton $appname"
echo ""
echo "##################################################################################"
echo "##################################################################################"
sleep 10
kubectl get svc -A | grep LoadBalancer | awk '{sub(/,.*/,""); print $5}' | while read HOST;do
echo -e "
apiVersion: entando.org/v1
kind: EntandoApp
metadata:
  namespace: $namespace
  name: $appname
spec:
  environmentVariables:
    - name: REDIS_ACTIVE 
      value: 'true'
    - name: REDIS_ADDRESSES 
      value: 'redis-node-0.redis-headless.default.svc.cluster.local:26379,redis-node-1.redis-headless.default.svc.cluster.local:26379'
    - name: SOLR_ADDRESS
      value: 'http://default-solr-solrcloud.$HOST.nip.io/solr'
  dbms: postgresql
  ingressHostName: $HOST.nip.io
  standardServerImage: wildfly
  replicas: 1" | kubectl apply -f -; done

sleep 200
while [[ $(kubectl get pods -l entando.org/entando-resource-kind=EntandoPlugin -n $namespace -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1 ; done
echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "solr url"
echo ""
echo "##################################################################################"
echo "##################################################################################"
kubectl get svc -A | grep LoadBalancer | awk '{sub(/,.*/,""); print $5}' |while read HOST;do
echo "http://default-solr-solrcloud.$HOST.nip.io/solr"; done

echo "##################################################################################"
echo "##################################################################################"
echo ""
echo "Entando url"
echo ""
echo "##################################################################################"
echo "##################################################################################"
kubectl get svc -A | grep LoadBalancer | awk '{sub(/,.*/,""); print $5}' |while read HOST;do
echo "http://$HOST.nip.io/app-builder/"; done