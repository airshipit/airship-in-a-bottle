export TEMP_DIR=${TEMP_DIR:-$(mktemp -d)}
export DEFINITION_DEPOT="${TEMP_DIR}/site_yaml/"
export CERT_DEPOT="${TEMP_DIR}/cert_yaml/"
export GATE_DEPOT="${TEMP_DIR}/gate_yaml/"
export SCRIPT_DEPOT="${TEMP_DIR}/scripts/"
export BUILD_WORK_DIR=${BUILD_WORK_DIR:-/work}
export BASE_IMAGE_SIZE=${BASE_IMAGE_SIZE:-68719476736}
export BASE_IMAGE_URL=${BASE_IMAGE_URL:-https://cloud-images.ubuntu.com/releases/xenial/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img}
export IMAGE_PROMENADE_CLI=${IMAGE_PROMENADE_CLI:-quay.io/airshipit/promenade:cfb8aa498c294c2adbc369ba5aaee19b49550d22}
export IMAGE_PEGLEG_CLI=${IMAGE_PEGLEG_CLI:-quay.io/airshipit/pegleg:ac6297eae6c51ab2f13a96978abaaa10cb46e3d6}
export IMAGE_SHIPYARD_CLI=${IMAGE_SHIPYARD_CLI:-quay.io/airshipit/shipyard:4dd6b484d11e86ad51da733841b9ef137421d461}
export IMAGE_COREDNS=${IMAGE_COREDNS:-docker.io/coredns/coredns:1.2.2}
export IMAGE_DRYDOCK_CLI=${IMAGE_DRYDOCK_CLI:-quay.io/airshipit/drydock:d93d6d5a0a370ced536180612d1ade708e29cd47}
export PROMENADE_DEBUG=${PROMENADE_DEBUG:-0}
export REGISTRY_DATA_DIR=${REGISTRY_DATA_DIR:-/mnt/registry}
export VIRSH_POOL=${VIRSH_POOL:-airship}
export VIRSH_POOL_PATH=${VIRSH_POOL_PATH:-/var/lib/libvirt/airship}
export VIRSH_CPU_OPTS=${VIRSH_CPU_OPTS:-host}
export UPSTREAM_DNS=${UPSTREAM_DNS:-"8.8.8.8 8.8.4.4"}
export NTP_POOLS=${NTP_POOLS:-"0.ubuntu.pool.ntp.org 1.ubuntu.pool.ntp.org"}
export NTP_SERVERS=${NTP_SERVERS:-""}

export SHIPYARD_PASSWORD=${SHIPYARD_OS_PASSWORD:-'password18'}
export AIRSHIP_KEYSTONE_URL=${AIRSHIP_KEYSTONE_URL:-'http://keystone.gate.local:80/v3'}

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

config_vm_io() {
    nodename=${1}
    io_profile=$(jq -cr ".vm.${nodename}.io_profile" < "${GATE_MANIFEST}")
    if [[ -z "$io_profile" ]]
    then
      io_profile="fast"
    fi
    echo -n "$io_profile"
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

config_vm_userdata() {
    nodename=${1}
    val=$(jq -cr ".vm.${nodename}.userdata" < "${GATE_MANIFEST}")

    if [[ "${val}" != "null" ]]
    then
      echo "${val}"
    fi
}

config_ingress_domain() {
    jq -cr '.ingress.domain' < "${GATE_MANIFEST}"
}

config_ingress_ca() {
    if [[ ! -z "$GATE_MANIFEST" ]]
    then
      jq -cr '.ingress.ca' < "${GATE_MANIFEST}"
    fi
}

config_ingress_ips() {
    jq -cr '.ingress | keys | map(select(test("([0-9]{1,3}.?){4}"))) | join(" ")' < "${GATE_MANIFEST}"
}

config_ingress_entries() {
    IP=$1
    jq -cr ".ingress[\"${IP}\"] | join(\" \")" < "${GATE_MANIFEST}"
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

join_array() {
  local IFS=$1
  shift
  echo "$*"
}
