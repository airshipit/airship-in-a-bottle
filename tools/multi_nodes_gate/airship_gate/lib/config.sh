export TEMP_DIR=${TEMP_DIR:-$(mktemp -d)}
export DEFINITION_DEPOT="${TEMP_DIR}/site_yaml/"
export CERT_DEPOT="${TEMP_DIR}/cert_yaml/"
export GATE_DEPOT="${TEMP_DIR}/gate_yaml/"
export SCRIPT_DEPOT="${TEMP_DIR}/scripts/"
export GENESIS_WORK_DIR=${GENESIS_WORK_DIR:-/work/}
export BASE_IMAGE_SIZE=${BASE_IMAGE_SIZE:-68719476736}
export BASE_IMAGE_URL=${BASE_IMAGE_URL:-https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img}
export IMAGE_PROMENADE_CLI=${IMAGE_PROMENADE_CLI:-quay.io/airshipit/promenade:master}
export IMAGE_PEGLEG_CLI=${IMAGE_PEGLEG_CLI:-quay.io/airshipit/pegleg:master}
export IMAGE_SHIPYARD_CLI=${IMAGE_SHIPYARD_CLI:-quay.io/airshipit/shipyard:master}
export PROMENADE_DEBUG=${PROMENADE_DEBUG:-0}
export SHIPYARD_PASSWORD=${SHIPYARD_OS_PASSWORD:-password18}
export REGISTRY_DATA_DIR=${REGISTRY_DATA_DIR:-/mnt/registry}
export VIRSH_POOL=${VIRSH_POOL:-airship}
export VIRSH_POOL_PATH=${VIRSH_POOL_PATH:-/var/lib/libvirt/airship}

config_vm_memory() {
    nodename=${1}
    jq -cr ".vm.${nodename}.memory" < "${GATE_MANIFEST}"
}

config_vm_names() {
    jq -cr '.vm | keys | join(" ")' < "${GATE_MANIFEST}"
}

config_vm_ip() {
    nodename=${1}
    jq -cr ".vm.${nodename}.ip" < "${GATE_MANIFEST}"
}

config_vm_mac() {
    nodename=${1}
    jq -cr ".vm.${nodename}.mac" < "${GATE_MANIFEST}"
}

config_vm_vcpus() {
    nodename=${1}
    jq -cr ".vm.${nodename}.vcpus" < "${GATE_MANIFEST}"
}

config_vm_bootstrap() {
    nodename=${1}
    val=$(jq -cr ".vm.${nodename}.bootstrap" < "${GATE_MANIFEST}")
    if [[ "${val}" == "true" ]]
    then
      echo "true"
    else
      echo "false"
    fi
}

config_pegleg_primary_repo() {
    jq -cr ".configuration.primary_repo" < "${GATE_MANIFEST}"
}

config_pegleg_sitename() {
    jq -cr ".configuration.site" < "${GATE_MANIFEST}"
}

config_pegleg_aux_repos() {
    jq -cr '.configuration.aux_repos | join(" ")' < "${GATE_MANIFEST}"
}
