#!/bin/bash
#
# Copyright 2018 AT&T Intellectual Property.  All other rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################
#                                                                             #
# Set up and deploy a UCP environment for development/testing purposes.       #
# Many of the defaults and sources used here are NOT production ready, and    #
# this should not be used as a copy/paste source for any production use.      #
#                                                                             #
###############################################################################

set -x

# IMPORTANT:
# If the directory for ucp-integration is already cloned into $WORKSPACE,
# it will not be re-cloned. This can be used to set up different tests, like
# changing the versions and contents of the design before running this script

# The directory that will contain the copies of designs and repos from this script
WORKSPACE=${WORKSPACE:-"/root/deploy"}
export WORKSPACE
# The site to deploy
TARGET_SITE=${TARGET_SITE:-"dev"}
# The hostname for the genesis node

# The host name for the single-node deployment. e.g.: 'genesis'
HOSTNAME=${HOSTNAME:-""}
# The host ip for this single-node deployment. e.g.: '10.0.0.9'
HOSTIP=${HOSTIP:-""}
# The cidr for the network for the host. e.g.: '10.0.0.0/24'
HOSTCIDR=${HOSTCIDR:-""}
# The interface on the host/genesis node. e.g.: 'ens3'
NODE_NET_IFACE=${NODE_NET_IFACE:-""}


# Repositories
UCP_INTEGRATION_REPO=${UCP_INTEGRATION_REPO:-"https://github.com/att-comdev/ucp-integration"}
UCP_INTEGRATION_REFSPEC=${UCP_INTEGRATION_REFSPEC:-""}
PEGLEG_REPO=${PEGLEG_REPO:-"https://github.com/att-comdev/pegleg.git"}
PEGLEG_REFSPEC=${PEGLEG_REFSPEC:-""}
SHIPYARD_REPO=${SHIPYARD_REPO:-"https://github.com/att-comdev/shipyard.git"}
SHIPYARD_REFSPEC=${SHIPYARD_REFSPEC:-""}

# Images
PEGLEG_IMAGE=${PEGLEG_IMAGE:-"artifacts-aic.atlantafoundry.com/att-comdev/pegleg:latest"}
PROMENADE_IMAGE=${PROMENADE_IMAGE:-"quay.io/attcomdev/promenade:latest"}

# Command shortcuts
PEGLEG=${WORKSPACE}/pegleg/tools/pegleg.sh

function check_preconditions() {
  set +x
  fail=false
  if ! [ $(id -u) = 0 ] ; then
    echo "Please execute this script as root!"
    fail=true
  fi
  if [ -z ${HOSTIP} ] ; then
    echo "The HOSTIP variable must be set. E.g. 10.0.0.9"
    fail=true
  fi
  if [ -z ${HOSTNAME} ] ; then
    echo "The HOSTNAME variable must be set. E.g. testvm1"
    fail=true
  fi
  if [ -z ${HOSTCIDR} ] ; then
    echo "The HOSTCIDR variable must be set. E.g. 10.0.0.0/24"
    fail=true
  fi
  if [ -z ${NODE_NET_IFACE} ] ; then
    echo "The NODE_NET_IFACE variable must be set. E.g. ens3"
    fail=true
  fi
  if [[ -z $(grep $HOSTNAME /etc/hosts | grep $HOSTIP) ]]
  then
    echo "No /etc/hosts entry found for $HOSTNAME. Please add one."
    fail=true
  fi
  if [ $fail = true ] ; then
    echo "Preconditions failed"
    exit 1
  fi
  set -x
}

function setup_workspace() {
  # Setup workspace directories
  mkdir -p ${WORKSPACE}/collected
  mkdir -p ${WORKSPACE}/genesis
  # Open permissions for output from promenade
  chmod -R 777 ${WORKSPACE}/genesis
}

function get_repo() {
  # Setup a repository in the workspace
  #
  # $1 = name of directory the repo will clone to
  # $2 = repository url
  # $3 = refspec of repo pull
  cd ${WORKSPACE}
  if [ ! -d "$1" ] ; then
    git clone $2
    if [ -n "$3" ] ; then
      cd $1
      git pull $2 $3
      cd ..
    fi
  fi
}

function setup_repos() {
  # Clone and pull the various git repos
  # Get pegleg for the script only. Image is separately referenced.
  get_repo pegleg ${PEGLEG_REPO} ${PEGLEG_REFSPEC}
  # Get ucp-integration for the design
  get_repo ucp-integration ${UCP_INTEGRATION_REPO} ${UCP_INTEGRATION_REFSPEC}
  # Get Shipyard for use after genesis
  get_repo shipyard ${SHIPYARD_REPO} ${SHIPYARD_REFSPEC}
}

function configure_dev_configurables() {
  cat << EOF >> ${WORKSPACE}/ucp-integration/deployment_files/site/${TARGET_SITE}/deployment/dev-configurables.yaml
data:
  hostname: ${HOSTNAME}
  hostip: ${HOSTIP}
  hostcidr: ${HOSTCIDR}
  interface: ${NODE_NET_IFACE}
EOF
}

function install_intermediate_certs() {
    set +x
    echo "Installing intermediate certs for AT&T cLCP Artifactory."
    set -x
    curl -L --insecure -o /usr/local/share/ca-certificates/gd_bundle-g2.crt https://certs.godaddy.com/repository/gd_bundle-g2.crt
    update-ca-certificates
}

function install_dependencies() {
    apt -qq update
    # Install docker
    apt -y install docker.io jq
}

function run_pegleg_collect() {
  # Runs pegleg collect to get the documents combined
  IMAGE=${PEGLEG_IMAGE} ${PEGLEG} site -p /workspace/ucp-integration/deployment_files collect ${TARGET_SITE} -s /workspace/collected
}

function generate_certs() {
  # Runs the generation of certs by promenade and builds bootstrap scripts
  # Note: In the really real world, CAs and certs would be provided as part of
  #   the supplied design. In this dev/test environment, self signed is fine.
  # Moves the generated certificates from /genesis to the design, so that a
  # Lint can be run
  set +x
  echo "=== Generating updated certificates ==="
  set -x
  # Copy the collected yamls into the target for the certs
  cp "${WORKSPACE}/collected"/*.yaml ${WORKSPACE}/genesis

  docker run --rm -t \
      -e http_proxy=$PROXY \
      -e https_proxy=$PROXY \
      -w /target \
      -e PROMENADE_DEBUG=false \
      -v ${WORKSPACE}/genesis:/target \
      ${PROMENADE_IMAGE} \
          promenade \
              generate-certs \
                  -o /target \
                  $(ls ${WORKSPACE}/genesis)

  # Copy the generated certs back into the deployment_files structure
  cp ${WORKSPACE}/genesis/certificates.yaml ${WORKSPACE}/ucp-integration/deployment_files/site/${TARGET_SITE}/secrets
}

function lint_design() {
  # After the certificates are in the deployment files run a pegleg lint
  IMAGE=${PEGLEG_IMAGE} ${PEGLEG} lint -p /workspace/ucp-integration/deployment_files
}

function generate_genesis() {
  # Generate the genesis scripts
  docker run --rm -t \
      -e http_proxy=$PROXY \
      -e https_proxy=$PROXY \
      -w /target \
      -e PROMENADE_DEBUG=false \
      -v ${WORKSPACE}/genesis:/target \
      ${PROMENADE_IMAGE} \
          promenade \
              build-all \
                  -o /target \
                  --validators \
                  $(ls ${WORKSPACE}/genesis)
}

function run_genesis() {
  # Runs the genesis script that was generated
  ${WORKSPACE}/genesis/genesis.sh
}

function validate_genesis() {
  # Vaidates the genesis deployment
  ${WORKSPACE}/genesis/validate-genesis.sh
}

function genesis_complete() {
  # Setup kubeconfig
  if [ ! -d "~/.kube" ] ; then
    mkdir ~/.kube
  fi
  cp -r /etc/kubernetes/admin/pki ~/.kube/pki
  cat /etc/kubernetes/admin/kubeconfig.yaml | sed -e 's/\/etc\/kubernetes\/admin/./' > ~/.kube/config

  # signals that genesis completed
  set +x
  echo "Genesis complete. "
  echo "The .yaml files in ${WORKSPACE} contain the site design that may be suitable for use with Shipyard. "
  echo "The Shipyard Keystone password may be found in ${WORKSPACE}/ucp-integration/deployment_files/site/${TARGET_SITE}/secrets/passphrases/ucp_shipyard_keystone_password.yaml"
  cat ${WORKSPACE}/ucp-integration/deployment_files/site/${TARGET_SITE}/secrets/passphrases/ucp_shipyard_keystone_password.yaml
  echo " "
  set -x
}

function setup_deploy_site() {
  # creates a directory /${WORKSPACE}/site with all the things necessary to run
  # deploy_site
  mkdir -p ${WORKSPACE}/site
  cp ${WORKSPACE}/ucp-integration/manifests/dev_single_node/creds.sh ${WORKSPACE}/site
  cp ${WORKSPACE}/genesis/*.yaml ${WORKSPACE}/site
  cp ${WORKSPACE}/shipyard/tools/run_shipyard.sh ${WORKSPACE}/site
  cp ${WORKSPACE}/shipyard/tools/shipyard_docker_base_command.sh ${WORKSPACE}/site
  set +x
  echo " "
  echo "${WORKSPACE}/site is now set up with creds.sh which can be sourced to set up credentials for use in running Shipyard"
  echo "${WORKSPACE}/site contains .yaml files that represent the single-node site deployment. (deployment_files.yaml, certificats.yaml)"
  echo " "
  echo "NOTE 2018-03-23: due to a bug in pegleg's document gathering, deployment_files.yaml may need to be updated to remove the duplicate SiteDefinition at the tail end of the file."
  echo "NOTE: If you changed the Shipyard keystone password (see above printouts), the creds.sh file needs to be updated to match before use."
  echo " "
  echo "----------------------------------------------------------------------------------"
  echo "The following commands will execute shipyard to setup and run a deploy_site action"
  echo "----------------------------------------------------------------------------------"
  echo "cd ${WORKSPACE}/site"
  echo "source creds.sh"
  echo "./run_shipyard.sh create configdocs design --filename=/home/shipyard/host/deployment_files.yaml"
  echo "./run_shipyard.sh create configdocs secrets --filename=/home/shipyard/host/certificates.yaml --append"
  echo "./run_shipyard.sh commit configdocs"
  echo "./run_shipyard.sh create action deploy_site"
  echo " "
  echo "-----------"
  echo "Other Notes"
  echo "-----------"
  echo "If you need to run armada directly to deploy charts (fix something broken?), the following maybe of use:"
  echo "export ARMADA_IMAGE=artifacts-aic.atlantafoundry.com/att-comdev/armada"
  echo "docker run -t -v ~/.kube:/armada/.kube -v ${WORKSPACE}/site:/target --net=host '${ARMADA_IMAGE}' apply /target/your-yaml.yaml"
  echo " "
  set -x
}


function clean() {
  # Perform any cleanup of temporary or unused artifacts
  set +x
  echo "To remove files generated during this script's execution, delete ${WORKSPACE}."
  set -x
}

function error() {
  # Processes errors
  set +x
  echo "Error when $1."
  set -x
  exit 1
}

trap clean EXIT

check_preconditions || error "checking for preconditions"
setup_workspace || error "setting up workspace directories"
setup_repos || error "setting up Git repos"
configure_dev_configurables || error "adding dev-configurables values"
install_intermediate_certs || error "installing intermediate certificates"
install_dependencies || error "installing dependencies"
run_pegleg_collect || error "running pegleg collect"
generate_certs || error "setting up certs with Promenade"
lint_design || error "linting the design"
generate_genesis || error "generating genesis"
run_genesis || error "running genesis"
validate_genesis || error "validating genesis"
genesis_complete || error "printing out some info about next steps"
setup_deploy_site || error "preparing the /site directory for deploy_site"