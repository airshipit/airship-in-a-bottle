rsync_cmd() {
    rsync -e "ssh -F ${SSH_CONFIG_DIR}/config" "${@}"
}

ssh_cmd_raw() {
    ssh -F "${SSH_CONFIG_DIR}/config" $@
}

ssh_cmd() {
    HOST=${1}
    shift
    args=$(shell-quote -- "${@}")
    if [[ -v GATE_DEBUG && ${GATE_DEBUG} = "1" ]]; then
        ssh -F "${SSH_CONFIG_DIR}/config" -v "${HOST}" "${args}"
    else
        ssh -F "${SSH_CONFIG_DIR}/config" "${HOST}" "${args}"
    fi
}

ssh_config_declare() {
    log Creating SSH config
    env -i \
      "SSH_CONFIG_DIR=${SSH_CONFIG_DIR}" \
      envsubst < "${TEMPLATE_DIR}/ssh-config-global.sub" > "${SSH_CONFIG_DIR}/config"
    for n in $(config_vm_names)
    do
      env -i \
        "SSH_CONFIG_DIR=${SSH_CONFIG_DIR}" \
        "SSH_NODE_HOSTNAME=${n}" \
        "SSH_NODE_IP=$(config_vm_ip ${n})" \
          envsubst < "${TEMPLATE_DIR}/ssh-config-node.sub" >> "${SSH_CONFIG_DIR}/config"
      if [[ "$(config_vm_bootstrap ${n})" == "true" ]]
      then
        echo "    User root" >> "${SSH_CONFIG_DIR}/config"
      else
        echo "    User ubuntu" >> "${SSH_CONFIG_DIR}/config"
      fi
    done
}

ssh_keypair_declare() {
    log Validating SSH keypair exists
    if [ ! -s "${SSH_CONFIG_DIR}/id_rsa" ]; then
        log Generating SSH keypair
        ssh-keygen -N '' -f "${SSH_CONFIG_DIR}/id_rsa" &>> "${LOG_FILE}"
    fi
}

ssh_load_pubkey() {
    cat "${SSH_CONFIG_DIR}/id_rsa.pub"
}

ssh_setup_declare() {
    mkdir -p "${SSH_CONFIG_DIR}"
    ssh_keypair_declare
    ssh_config_declare
}

ssh_wait() {
    NAME=${1}
    while ! ssh_cmd "${NAME}" /bin/true; do
        sleep 0.5
    done
}
