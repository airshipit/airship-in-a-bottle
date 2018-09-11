set -e

LIB_DIR=$(realpath "$(dirname "${BASH_SOURCE}")")
REPO_ROOT=$(realpath "$(dirname "${BASH_SOURCE}")/../../../..")

source "$LIB_DIR"/config.sh
source "$LIB_DIR"/const.sh
source "$LIB_DIR"/docker.sh
source "$LIB_DIR"/kube.sh
source "$LIB_DIR"/log.sh
source "$LIB_DIR"/nginx.sh
source "$LIB_DIR"/promenade.sh
source "$LIB_DIR"/registry.sh
source "$LIB_DIR"/ssh.sh
source "$LIB_DIR"/virsh.sh
source "$LIB_DIR"/airship.sh
source "$LIB_DIR"/ingress.sh

if [[ -v GATE_DEBUG && ${GATE_DEBUG} = "1" ]]; then
    set -x
fi
