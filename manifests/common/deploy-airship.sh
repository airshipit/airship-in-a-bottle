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
# Set up and deploy an Airship environment for development/testing purposes.  #
# Many of the defaults and sources used here are NOT production ready, and    #
# this should not be used as a copy/paste source for any production use.      #
#                                                                             #
###############################################################################

set -x

# IMPORTANT:
# If the directory for airship-in-a-bottle is already cloned into $WORKSPACE,
# it will not be re-cloned. This can be used to set up different tests, like
# changing the versions and contents of the design before running this script

# The last step to run through in this script. Valid Values are "collect",
# "genesis", "deploy", and "demo". By default this will run through to the end
# of the genesis steps
LAST_STEP_NAME=${1:-"genesis"}

if [[ ${LAST_STEP_NAME} == "collect" ]]; then
  STEP_BREAKPOINT=10
elif [[ ${LAST_STEP_NAME} == "genesis" ]]; then
  STEP_BREAKPOINT=20
elif [[ ${LAST_STEP_NAME} == "deploy" ]]; then
  STEP_BREAKPOINT=30
elif [[ ${LAST_STEP_NAME} == "demo" ]]; then
  STEP_BREAKPOINT=40
else
  STEP_BREAKPOINT=20
fi

# The directory that will contain the copies of designs and repos from this script
export WORKSPACE=${WORKSPACE:-"/root/deploy"}

# The site to deploy
TARGET_SITE=${TARGET_SITE:-"dev"}

# The host name for the single-node deployment. e.g.: 'genesis'
SHORT_HOSTNAME=${SHORT_HOSTNAME:-""}
# The host ip for this single-node deployment. e.g.: '10.0.0.9'
HOSTIP=${HOSTIP:-""}
# The cidr for the network for the host. e.g.: '10.0.0.0/24'
HOSTCIDR=${HOSTCIDR:-""}
# The interface on the host/genesis node. e.g.: 'ens3'
NODE_NET_IFACE=${NODE_NET_IFACE:-""}
# Allowance for Genesis/Armada to settle in seconds:
POST_GENESIS_DELAY=${POST_GENESIS_DELAY:-60}


# Repositories
AIRSHIP_IN_A_BOTTLE_REPO=${AIRSHIP_IN_A_BOTTLE_REPO:-"https://github.com/openstack/airship-in-a-bottle"}
AIRSHIP_IN_A_BOTTLE_REFSPEC=${AIRSHIP_IN_A_BOTTLE_REFSPEC:-""}
PEGLEG_REPO=${PEGLEG_REPO:-"https://github.com/openstack/airship-pegleg.git"}
PEGLEG_REFSPEC=${PEGLEG_REFSPEC:-""}
SHIPYARD_REPO=${SHIPYARD_REPO:-"https://github.com/openstack/airship-shipyard.git"}
SHIPYARD_REFSPEC=${SHIPYARD_REFSPEC:-""}

# Images
PEGLEG_IMAGE=${PEGLEG_IMAGE:-"artifacts-aic.atlantafoundry.com/att-comdev/pegleg:ef47933903047339bd63fcfa265dfe4296e8a322"}
PROMENADE_IMAGE=${PROMENADE_IMAGE:-"docker.io/sthussey/promenade:replace"}

# Command shortcuts
PEGLEG=${WORKSPACE}/airship-pegleg/tools/pegleg.sh

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
  if [ -z ${SHORT_HOSTNAME} ] ; then
    echo "The SHORT_HOSTNAME variable must be set. E.g. testvm1"
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
  if [[ -z $(grep $SHORT_HOSTNAME /etc/hosts | grep $HOSTIP) ]]
  then
    echo "No /etc/hosts entry found for $SHORT_HOSTNAME. Please add one."
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
  # Open permissions for output from Promenade
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
  # Get airship-in-a-bottle for the design
  get_repo airship-in-a-bottle ${AIRSHIP_IN_A_BOTTLE_REPO} ${AIRSHIP_IN_A_BOTTLE_REFSPEC}
  # Get Shipyard for use after genesis
  get_repo shipyard ${SHIPYARD_REPO} ${SHIPYARD_REFSPEC}
}

function configure_dev_configurables() {
  cat << EOF >> ${WORKSPACE}/airship-in-a-bottle/deployment_files/site/${TARGET_SITE}/deployment/dev-configurables.yaml
data:
  hostname: ${SHORT_HOSTNAME}
  hostip: ${HOSTIP}
  hostcidr: ${HOSTCIDR}
  interface: ${NODE_NET_IFACE}
EOF
}

function install_dependencies() {
    apt -qq update
    # Install docker
    apt -y install --no-install-recommends docker.io jq nmap
}

function run_pegleg_collect() {
  # Runs pegleg collect to get the documents combined
  IMAGE=${PEGLEG_IMAGE} ${PEGLEG} site -p /workspace/airship-in-a-bottle/deployment_files collect ${TARGET_SITE} -s /workspace/collected
}

function generate_certs() {
  # Runs the generation of certs by Promenade and builds bootstrap scripts
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
  cp ${WORKSPACE}/genesis/certificates.yaml ${WORKSPACE}/airship-in-a-bottle/deployment_files/site/${TARGET_SITE}/secrets
}

function lint_design() {
  # After the certificates are in the deployment files run a pegleg lint
  IMAGE=${PEGLEG_IMAGE} ${PEGLEG} lint -p /workspace/airship-in-a-bottle/deployment_files
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
  if [ ! -d "$HOME/.kube" ] ; then
    mkdir ~/.kube
  fi
  cp -r /etc/kubernetes/admin/pki ~/.kube/pki
  cat /etc/kubernetes/admin/kubeconfig.yaml | sed -e 's/\/etc\/kubernetes\/admin/./' > ~/.kube/config

  set +x
  echo "-----------"
  echo "Waiting ${POST_GENESIS_DELAY} seconds for Genesis process to settle. This is a good time to grab a coffee :)"
  echo "-----------"
  sleep ${POST_GENESIS_DELAY}

  # signals that genesis completed
  echo "Genesis complete. "
  echo "The .yaml files in ${WORKSPACE} contain the site design that may be suitable for use with Shipyard. "
  echo "The Shipyard Keystone password may be found in ${WORKSPACE}/airship-in-a-bottle/deployment_files/site/${TARGET_SITE}/secrets/passphrases/ucp_shipyard_keystone_password.yaml"
  cat ${WORKSPACE}/airship-in-a-bottle/deployment_files/site/${TARGET_SITE}/secrets/passphrases/ucp_shipyard_keystone_password.yaml
  echo " "
  set -x
}

function setup_deploy_site() {
  # creates a directory /${WORKSPACE}/site with all the things necessary to run
  # deploy_site
  mkdir -p ${WORKSPACE}/site
  # TODO: (bryan-strassner) make creds.sh contain the Shipyard-Keystone
  #     password sourced from the target design used.
  cp ${WORKSPACE}/airship-in-a-bottle/manifests/common/creds.sh ${WORKSPACE}/site
  cp ${WORKSPACE}/genesis/*.yaml ${WORKSPACE}/site
  cp ${WORKSPACE}/airship-shipyard/tools/run_shipyard.sh ${WORKSPACE}/site
  cp ${WORKSPACE}/airship-shipyard/tools/shipyard_docker_base_command.sh ${WORKSPACE}/site
  cp ${WORKSPACE}/airship-shipyard/tools/execute_shipyard_action.sh ${WORKSPACE}/site
  set +x
  echo " "
  echo "${WORKSPACE}/site is now set up with creds.sh which can be sourced to set up credentials for use in running Shipyard"
  echo "${WORKSPACE}/site contains .yaml files that represent the single-node site deployment. (deployment_files.yaml, certificates.yaml)"
  echo " "
  echo "NOTE: If you changed the Shipyard keystone password (see above printouts), the creds.sh file needs to be updated to match before use."
  echo " "
  echo "----------------------------------------------------------------------------------"
  echo "The following commands will execute Shipyard to setup and run a deploy_site action"
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
  echo "If you need to run Armada directly to deploy charts (fix something broken?), the following may be of use:"
  echo "export ARMADA_IMAGE=artifacts-aic.atlantafoundry.com/att-comdev/armada"
  echo "docker run -t -v ~/.kube:/armada/.kube -v ${WORKSPACE}/site:/target --net=host '${ARMADA_IMAGE}' apply /target/your-yaml.yaml"
  echo " "
  set -x
}

function execute_deploy_site() {
  set +x
  echo " "
  echo "This is an automated deployment using Shipyard, running commands noted previously"
  echo "Please stand by while Shipyard deploys the site"
  echo " "
  set -x
  #Automate the steps of deploying a site.
  cd ${WORKSPACE}/site
  source creds.sh
  ./run_shipyard.sh create configdocs design --filename=/home/shipyard/host/deployment_files.yaml
  ./run_shipyard.sh create configdocs secrets --filename=/home/shipyard/host/certificates.yaml --append
  ./run_shipyard.sh commit configdocs
  # set variables used in execute_shipyard_action.sh
  export max_shipyard_count=${max_shipyard_count:-60}
  export shipyard_query_time=${shipyard_query_time:-90}
  # monitor the execution of deploy_site
  bash execute_shipyard_action.sh 'deploy_site'
}

function execute_create_heat_stack() {
  # TODO: (bryan-strassner) prevent this running unless we're running from a
  #     compatible site defintion that includes OpenStack
  set +x
  echo " "
  echo "Performing basic sanity checks by creating heat stacks"
  echo " "
  set -x
  # Switch to directory where the script is located
  cd ${WORKSPACE}/airship-in-a-bottle/manifests/dev_single_node
  bash test_create_heat_stack.sh
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


# Common steps for all breakpoints specified
check_preconditions || error "checking for preconditions"
setup_workspace || error "setting up workspace directories"
setup_repos || error "setting up Git repos"
configure_dev_configurables || error "adding dev-configurables values"
install_dependencies || error "installing dependencies"

# collect
if [[ ${STEP_BREAKPOINT} -ge 10 ]]; then
  run_pegleg_collect || error "running pegleg collect"
fi

# genesis
if [[ ${STEP_BREAKPOINT} -ge 20 ]]; then
  generate_certs || error "setting up certs with Promenade"
  # Temporarially disabled until lint_design works with a single node.
  # lint_design || error "linting the design"
  generate_genesis || error "generating genesis"
  run_genesis || error "running genesis"
  validate_genesis || error "validating genesis"
  genesis_complete || error "printing out some info about next steps"
  setup_deploy_site || error "preparing the /site directory for deploy_site"
fi

# deploy
if [[ ${STEP_BREAKPOINT} -ge 30 ]]; then
  execute_deploy_site || error "executing deploy_site from the /site directory"
fi

# demo
if [[ ${STEP_BREAKPOINT} -ge 40 ]]; then
  execute_create_heat_stack || error "creating heat stack"
fi
