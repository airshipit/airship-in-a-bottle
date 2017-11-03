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
export ARMADA_NODE_PORT=${ARMADA_NODE_PORT:-31903}

# Storage
export CEPH_OSD_DIR=${CEPH_OSD_DIR:-"/var/lib/openstack-helm/ceph/osd"}

# Hostnames
export GENESIS_NODE_NAME=${GENESIS_NODE_NAME:-"node1"}
export GENESIS_NODE_NAME=$(echo $GENESIS_NODE_NAME | tr [:upper:] [:lower:])
export MASTER_NODE_NAME=${MASTER_NODE_NAME:-"node2"}
export MASTER_NODE_NAME=$(echo $MASTER_NODE_NAME | tr [:upper:] [:lower:])

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

# Images
export DRYDOCK_IMAGE=${DRYDOCK_IMAGE:-"quay.io/attcomdev/drydock:master"}
export ARMADA_IMAGE=${ARMADA_IMAGE:-"quay.io/attcomdev/armada:master"}
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
deploy_counter=1
deploy_timeout=${1:-720}

check_timeout_counter() {

    # Check total elapsed time
    # The default time out is set to 1hr
    # This value can be changed by setting $1
    if [[ $deploy_counter -eq $deploy_timeout ]]; then
       echo 'UCP control plane deployment timed out.'
       break
    fi
}

while true; do
  # Check the status of drydock, deckhand, armada and shipyard api pod
  # Ignore db or ks related pod
  for i in drydock deckhand armada shipyard
  do
    while [[ -z $(kubectl get pods -n ucp | grep $i | grep -v db | grep -v ks | grep Running) ]]
    do
      ((deploy_counter++))
      check_timeout_counter
      sleep 5
    done
  done

  # Check that the total elapsed time is less than time out
  # Print message stating that UCP Control Plane is deployed
  if [[ $deploy_counter -lt $deploy_timeout ]]; then
    echo 'UCP control plane deployed.'
  fi

  # Exit while loop
  break
done
