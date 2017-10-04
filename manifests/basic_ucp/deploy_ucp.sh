#/bin/bash

set -x

# Check that we are root
if [[ $(whoami) != "root" ]]
then
  echo "Must be root to run $0"
  exit -1
fi


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

# Storage
export CEPH_OSD_DIR=${CEPH_OSD_DIR:-"/var/lib/openstack-helm/ceph/osd"}

# Hostnames
export GENESIS_NODE_NAME=${GENESIS_NODE_NAME:-"node1"}
export MASTER_NODE_NAME=${MASTER_NODE_NAME:-"node2"}

# Charts
export CEPH_CHART_REPO=${CEPH_CHART_REPO:-"https://github.com/openstack/openstack-helm"}
export CEPH_CHART_BRANCH=${CEPH_CHART_BRANCH:-"master"}
export DRYDOCK_CHART_REPO=${DRYDOCK_CHART_REPO:-"https://github.com/att-comdev/aic-helm"}
export DRYDOCK_CHART_BRANCH=${DRYDOCK_CHART_BRANCH:-"master"}
export MAAS_CHART_REPO=${MAAS_CHART_REPO:-"https://github.com/openstack/openstack-helm-addons"}
export MAAS_CHART_BRANCH=${MAAS_CHART_BRANCH:-"master"}
export DECKHAND_CHART_REPO=${DECKHAND_CHART_REPO:-"https://github.com/att-comdev/aic-helm"}
export DECKHAND_CHART_BRANCH=${DECKHAND_CHART_BRANCH:-"master"}
export SHIPYARD_CHART_REPO=${SHIPYARD_CHART_REPO:-"https://github.com/att-comdev/aic-helm"}
export SHIPYARD_CHART_BRANCH=${SHIPYARD_CHART_BRANCH:-"master"}

# Images
export DRYDOCK_IMAGE=${DRYDOCK_IMAGE:-"quay.io/attcomdev/drydock:0.2.0-a1"}
export ARMADA_IMAGE=${ARMADA_IMAGE:-"quay.io/attcomdev/armada:v0.6.0"}
export PROMENADE_IMAGE=${PROMENADE_IMAGE:-"quay.io/attcomdev/promenade:master"}
export DECKHAND_IMAGE=${DECKHAND_IMAGE:-"quay.io/attcomdev/deckhand:master"}
export SHIPYARD_IMAGE=${SHIPYARD_IMAGE:-"quay.io/attcomdev/shipyard:master"}
export AIRFLOW_IMAGE=${AIRFLOW_IMAGE:-"quay.io/attcomdev/airflow:master"}

# Filenames
export ARMADA_CONFIG=${ARMADA_CONFIG:-"armada.yaml"}
export PROMENADE_CONFIG=${PROMENADE_CONFIG:-"promenade.yaml"}
export UP_SCRIPT_FILE=${UP_SCRIPT_FILE:-"up.sh"}

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

if [[ $PROXY_ENABLED == 'true' ]]
then
  export http_proxy=$PROXY_ADDRESS
  export https_proxy=$PROXY_ADDRESS
  export HTTP_PROXY=$PROXY_ADDRESS
  export HTTPS_PROXY=$PROXY_ADDRESS
fi

# Install docker
apt -qq update
apt -y install docker.io jq

# Required inputs
#   Promenade input-config.yaml
#   Armada Manifest for integrated UCP services

cat promenade.yaml.sub | envsubst > ${PROMENADE_CONFIG}
cat armada.yaml.sub | envsubst > ${ARMADA_CONFIG}
rm -rf configs
mkdir configs

# Generate Promenade configuration
docker run -t -v $(pwd):/target ${PROMENADE_IMAGE} promenade generate -c /target/${PROMENADE_CONFIG} -o /target/configs

# Do Promenade genesis process
cd configs
sudo bash ${UP_SCRIPT_FILE} ./${GENESIS_NODE_NAME}.yaml
cd ..

# Setup kubeconfig
mkdir ~/.kube
cp -r /etc/kubernetes/admin/pki ~/.kube/pki
cat /etc/kubernetes/admin/kubeconfig.yaml | sed -e 's/\/etc\/kubernetes\/admin/./' > ~/.kube/config

# Polling to ensure genesis is complete
while [[ -z $(kubectl get pods -n kube-system | grep 'kube-dns' | grep -e '3/3') ]]
do
  sleep 5
done

# Squash Kubernetes RBAC to be compatible w/ OSH
kubectl update -f ./rbac-generous-permissions.yaml

# Do Armada deployment of UCP integrated services
docker run -t -v ~/.kube:/armada/.kube -v $(pwd):/target --net=host \
  ${ARMADA_IMAGE} apply /target/${ARMADA_CONFIG} --tiller-host=${GENESIS_NODE_IP} --tiller-port=44134

# Polling for UCP service deployment

while [[ -z $(kubectl get pods -n ucp | grep drydock | grep Running) ]]
do
  sleep 5
done

# Check the status of deckhand-api pod
# Ignore deckhand db or ks related pod
while [[ -z $(kubectl get pods -n ucp | grep deckhand | grep -v db | grep -v ks | grep Running) ]]
do
  sleep 5
done

# Check the status of shipyard-api pod
# Ignore shipyard db or ks related pod
while [[ -z $(kubectl get pods -n ucp | grep shipyard | grep -v db | grep -v ks | grep Running) ]]
do
  sleep 5
done

echo 'UCP control plane deployed.'
