#!/bin/bash

set -x

# Check that we are root
if [[ $(whoami) != "root" ]]
then
  echo "Must be root to run $0"
  exit -1
fi

function init_env {
    # Setup environmental variables
    # with stable defaults

    # Network
    export CEPH_CLUSTER_NET=${CEPH_CLUSTER_NET:-"NA"}
    export CEPH_PUBLIC_NET=${CEPH_PUBLIC_NET:-"NA"}
    export GENESIS_NODE_IP=${GENESIS_NODE_IP:-"NA"}
    export DRYDOCK_NODE_IP=${DRYDOCK_NODE_IP:-${GENESIS_NODE_IP}}
    export DRYDOCK_NODE_PORT=${DRYDOCK_NODE_PORT:-31000}
    export MAAS_NODE_IP=${MAAS_NODE_IP:-${GENESIS_NODE_IP}}
    export MAAS_NODE_PORT=${MAAS_NODE_PORT:-31900}
    export MASTER_NODE_IP=${MASTER_NODE_IP:-"NA"}
    export NODE_NET_IFACE=${NODE_NET_IFACE:-"eth0"}
    export PROXY_ADDRESS=${PROXY_ADDRESS:-"http://one.proxy.att.com:8080"}
    export PROXY_ENABLED=${PROXY_ENABLED:-"false"}
    export AIRFLOW_NODE_PORT=${AIRFLOW_NODE_PORT:-32080}
    export SHIPYARD_NODE_PORT=${SHIPYARD_NODE_PORT:-31901}
    export ARMADA_NODE_PORT=${ARMADA_NODE_PORT:-31903}

    # UCP Service Config
    export SHIPYARD_PROD_DEPLOY=${SHIPYARD_PROD_DEPLOY:-"true"}
    export AIRFLOW_PATH_DAG=${AIRFLOW_PATH_DAG:-"/var/tmp/airflow/dags"}
    export AIRFLOW_PATH_PLUGIN=${AIRFLOW_PATH_PLUGIN:-"/var/tmp/airflow/plugins"}
    export AIRFLOW_PATH_LOG=${AIRFLOW_PATH_LOG:-"/var/tmp/airflow/logs"}
    export MAAS_CACHE_ENABLED=${MAAS_CACHE_ENABLED:-"false"}
    # NOTE - Pool size of 1 is NOT production-like. Workaround for Ceph Luminous
    # until disk targetting is implemented to have multiple OSDs on Genesis
    export CEPH_OSD_POOL_SIZE=${CEPH_OSD_POOL_SIZE:-"1"}

    # Storage
    export CEPH_OSD_DIR=${CEPH_OSD_DIR:-"/var/lib/openstack-helm/ceph/osd"}
    export ETCD_KUBE_DATA_PATH=${ETCD_KUBE_DATA_PATH:-"/var/lib/etcd/kubernetes"}
    export ETCD_KUBE_ETC_PATH=${ETCD_KUBE_ETC_PATH:-"/etc/etcd/kubernetes"}
    export ETCD_CALICO_DATA_PATH=${ETCD_CALICO_DATA_PATH:-"/var/lib/etcd/calico"}
    export ETCD_CALICO_ETC_PATH=${ETCD_CALICO_ETC_PATH:-"/etc/etcd/calico"}

    # Hostnames
    export GENESIS_NODE_NAME=${GENESIS_NODE_NAME:-"node1"}
    export GENESIS_NODE_NAME=$(echo $GENESIS_NODE_NAME | tr '[:upper:]' '[:lower:]')
    export MASTER_NODE_NAME=${MASTER_NODE_NAME:-"node2"}
    export MASTER_NODE_NAME=$(echo $MASTER_NODE_NAME | tr '[:upper:]' '[:lower:]')

    # Charts
    export HTK_CHART_REPO=${HTK_CHART_REPO:-"https://github.com/openstack/openstack-helm"}
    export HTK_CHART_PATH=${HTK_CHART_PATH:-"helm-toolkit"}
    export HTK_CHART_BRANCH=${HTK_CHART_BRANCH:-"master"}
    export CEPH_CHART_REPO=${CEPH_CHART_REPO:-"https://github.com/openstack/openstack-helm"}
    export CEPH_CHART_PATH=${CEPH_CHART_PATH:-"ceph"}
    export CEPH_CHART_BRANCH=${CEPH_CHART_BRANCH:-"master"}
    export DRYDOCK_CHART_REPO=${DRYDOCK_CHART_REPO:-"https://github.com/att-comdev/drydock"}
    export DRYDOCK_CHART_PATH=${DRYDOCK_CHART_PATH:-"charts/drydock"}
    export DRYDOCK_CHART_BRANCH=${DRYDOCK_CHART_BRANCH:-"master"}
    export MAAS_CHART_REPO=${MAAS_CHART_REPO:-"https://github.com/att-comdev/maas"}
    export MAAS_CHART_PATH=${MAAS_CHART_PATH:-"charts/maas"}
    export MAAS_CHART_BRANCH=${MAAS_CHART_BRANCH:-"master"}
    export DECKHAND_CHART_REPO=${DECKHAND_CHART_REPO:-"https://github.com/att-comdev/deckhand"}
    export DECKHAND_CHART_PATH=${DECKHAND_CHART_PATH:-"charts/deckhand"}
    export DECKHAND_CHART_BRANCH=${DECKHAND_CHART_BRANCH:-"master"}
    export SHIPYARD_CHART_REPO=${SHIPYARD_CHART_REPO:-"https://github.com/att-comdev/shipyard"}
    export SHIPYARD_CHART_PATH=${SHIPYARD_CHART_PATH:-"charts/shipyard"}
    export SHIPYARD_CHART_BRANCH=${SHIPYARD_CHART_BRANCH:-"master"}
    export ARMADA_CHART_REPO=${ARMADA_CHART_REPO:-"https://github.com/att-comdev/armada"}
    export ARMADA_CHART_PATH=${ARMADA_CHART_PATH:-"charts/armada"}
    export ARMADA_CHART_BRANCH=${ARMADA_CHART_BRANCH:-"master"}

    #Kubernetes artifacts
    export KUBE_PROXY_IMAGE=${KUBE_PROXY_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_ETCD_IMAGE=${KUBE_ETCD_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_ETCDCTL_IMAGE=${KUBE_ETCDCTL_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_ANCHOR_IMAGE=${KUBE_ANCHOR_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_COREDNS_IMAGE=${KUBE_COREDNS_IMAGE:-"coredns/coredns:0.9.9"}
    export KUBE_APISERVER_IMAGE=${KUBE_APISERVER_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_CTLRMGR_IMAGE=${KUBE_CTLRMGR_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBE_SCHED_IMAGE=${KUBE_SCHED_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export KUBECTL_IMAGE=${KUBECTL_IMAGE:-"gcr.io/google_containers/hyperkube-amd64:v1.8.6"}
    export CALICO_CNI_IMAGE=${CALICO_CNI_IMAGE:-"quay.io/calico/cni:v1.11.0"}
    export CALICO_CTL_IMAGE=${CALICO_CTL_IMAGE:-"quay.io/calico/ctl:v1.6.1"}
    export CALICO_NODE_IMAGE=${CALICO_NODE_IMAGE:-"quay.io/calico/node:v2.6.1"}
    export CALICO_POLICYCTLR_IMAGE=${CALICO_POLICYCTLR_IMAGE:-"quay.io/calico/kube-controllers:v1.0.0"}
    export CALICO_ETCD_IMAGE=${CALICO_ETCD_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export CALICO_ETCDCTL_IMAGE=${CALICO_ETCDCTL_IMAGE:-"quay.io/coreos/etcd:v3.0.17"}
    export KUBE_KUBELET_TAR=${KUBE_KUBELET_TAR:-"https://dl.k8s.io/v1.8.6/kubernetes-node-linux-amd64.tar.gz"}

    # Images
    export TILLER_IMAGE=${TILLER_IMAGE:-"gcr.io/kubernetes-helm/tiller:v2.7.2"}
    export DRYDOCK_IMAGE=${DRYDOCK_IMAGE:-"quay.io/attcomdev/drydock:latest"}
    export ARMADA_IMAGE=${ARMADA_IMAGE:-"quay.io/attcomdev/armada:latest"}
    export PROMENADE_IMAGE=${PROMENADE_IMAGE:-"quay.io/attcomdev/promenade:latest"}
    export DECKHAND_IMAGE=${DECKHAND_IMAGE:-"quay.io/attcomdev/deckhand:latest"}
    export SHIPYARD_IMAGE=${SHIPYARD_IMAGE:-"quay.io/attcomdev/shipyard:latest"}
    export AIRFLOW_IMAGE=${AIRFLOW_IMAGE:-"quay.io/attcomdev/airflow:latest"}
    export MAAS_CACHE_IMAGE=${MAAS_CACHE_IMAGE:-"quay.io/attcomdev/maas-cache:latest"}
    export MAAS_REGION_IMAGE=${MAAS_REGION_IMAGE:-"quay.io/attcomdev/maas-region:latest"}
    export MAAS_RACK_IMAGE=${MAAS_RACK_IMAGE:-"quay.io/attcomdev/maas-rack:latest"}

    # Docker
    export DOCKER_REPO_URL=${DOCKER_REPO_URL:-"http://apt.dockerproject.org/repo"}
    export DOCKER_PACKAGE=${DOCKER_PACKAGE:-"docker-engine=1.13.1-0~ubuntu-xenial"}

    # Filenames
    export ARMADA_CONFIG=${ARMADA_CONFIG:-"armada.yaml"}
    export UP_SCRIPT_FILE=${UP_SCRIPT_FILE:-"genesis.sh"}

    # Validate environment
    if [[ $GENESIS_NODE_IP == "NA" || $MASTER_NODE_IP == "NA" ]]
    then
      echo "GENESIS_NODE_IP and MASTER_NODE_IP env vars must be set to correct IP addresses."
      exit -1
    fi

    if [[ $CEPH_CLUSTER_NET == "NA" || $CEPH_PUBLIC_NET == "NA" ]]
    then
      echo "CEPH_CLUSTER_NET and CEPH_PUBLIC_NET env vars must be set to correct IP subnet CIDRs."
      exit -1
    fi

    if [[ $(hostname) != $GENESIS_NODE_NAME ]]
    then
      echo "Local node hostname $(hostname) does not match GENESIS_NODE_NAME $GENESIS_NODE_NAME."
      exit -1
    fi

    if [[ -z $(grep $GENESIS_NODE_NAME /etc/hosts | grep $GENESIS_NODE_IP) ]]
    then
      echo "No /etc/hosts entry found for $GENESIS_NODE_NAME. Please add one."
      exit -1
    fi

    echo "Saving deployment environment to deploy-env.sh."
    env | xargs -n 1 -d '\n' echo "export" >> deploy-env.sh
}

function genesis {
    rm -rf configs
    mkdir configs
    chmod 777 configs

    cat joining-host-config.yaml.sub | envsubst > configs/joining-host-config.yaml
    cat armada-resources.yaml.sub | envsubst > configs/armada-resources.yaml
    cat armada.yaml.sub | envsubst > ${ARMADA_CONFIG}
    cat Genesis.yaml.sub | envsubst > configs/Genesis.yaml
    cat HostSystem.yaml.sub | envsubst > configs/HostSystem.yaml
    cp Kubelet.yaml.sub configs/Kubelet.yaml
    cp KubernetesNetwork.yaml.sub configs/KubernetesNetwork.yaml
    cp Docker.yaml configs/
    cp ArmadaManifest.yaml configs/

    if [[ $PROXY_ENABLED == 'true' ]]
    then
      export http_proxy=$PROXY_ADDRESS
      export https_proxy=$PROXY_ADDRESS
      export HTTP_PROXY=$PROXY_ADDRESS
      export HTTPS_PROXY=$PROXY_ADDRESS
      echo '  proxy:' >> configs/KubernetesNetwork.yaml
      echo "    url: ${PROXY_ADDRESS}" >> configs/KubernetesNetwork.yaml
    fi

    # Support a custom deployment for shipyard developers

    if [[ $SHIPYARD_PROD_DEPLOY == 'false' ]]
    then
      mkdir -p $AIRFLOW_PATH_DAG
      mkdir -p $AIRFLOW_PATH_PLUGIN
      mkdir -p $AIRFLOW_PATH_LOG
    fi

    # Install docker
    apt -qq update
    apt -y install docker.io jq

    # Generate certificates
    docker run --rm -t -w /target -v $(pwd)/configs:/target ${PROMENADE_IMAGE} promenade generate-certs -o /target $(ls ./configs)

    if [[ $? -ne 0 ]]
    then
      echo "Promenade certificate generation failed."
      exit
    fi

    # Generate promenade join artifactos
    docker run --rm -t -w /target -v $(pwd)/configs:/target ${PROMENADE_IMAGE} promenade build-all -o /target --validators $(ls ./configs)

    if [[ $? -ne 0 ]]
    then
      echo "Promenade join artifact generation failed."
      exit
    fi

    # Do Promenade genesis process
    cd configs
    . ${UP_SCRIPT_FILE}
    cd ..

    if [[ $? -ne 0 ]]
    then
      echo "Genesis process failed."
      exit
    fi

    # Setup kubeconfig
    mkdir ~/.kube
    cp -r /etc/kubernetes/admin/pki ~/.kube/pki
    cat /etc/kubernetes/admin/kubeconfig.yaml | sed -e 's/\/etc\/kubernetes\/admin/./' > ~/.kube/config
}

function helm_init {
    # Run helm init since promenade tears down temporary tiller
    helm init
}

function ucp_deploy {
    while [[ -z $(kubectl get pods -n kube-system | grep tiller | grep Running) ]]
    do
      echo 'Waiting for tiller to be ready.'
      sleep 10
    done

    docker run -t -v ~/.kube:/armada/.kube -v $(pwd):/target --net=host ${ARMADA_IMAGE} apply /target/${ARMADA_CONFIG}

    echo 'UCP control plane deployed.'
}

init_env
genesis
helm_init
ucp_deploy
