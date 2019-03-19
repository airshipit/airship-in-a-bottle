img_base_declare() {
    log Validating base image exists
    if ! virsh vol-key --pool "${VIRSH_POOL}" --vol airship-gate-base.img > /dev/null; then
        log Installing base image from "${BASE_IMAGE_URL}"

        cd "${TEMP_DIR}"
        curl -q -L -o base.img "${BASE_IMAGE_URL}"

        {
            virsh vol-create-as \
                --pool "${VIRSH_POOL}" \
                --name airship-gate-base.img \
                --format qcow2 \
                --capacity "${BASE_IMAGE_SIZE}" \
                --prealloc-metadata
            virsh vol-upload \
                --vol airship-gate-base.img \
                --file base.img \
                --pool "${VIRSH_POOL}"
        } &>> "${LOG_FILE}"
    fi
}

iso_gen() {
    NAME=${1}
    ADDL_USERDATA="${2}"

    if virsh vol-key --pool "${VIRSH_POOL}" --vol "cloud-init-${NAME}.iso" &> /dev/null; then
        log Removing existing cloud-init ISO for "${NAME}"
        virsh vol-delete \
            --pool "${VIRSH_POOL}" \
            --vol "cloud-init-${NAME}.iso" &>> "${LOG_FILE}"
    fi

    log "Creating cloud-init ISO for ${NAME}"
    ISO_DIR=${TEMP_DIR}/iso/${NAME}
    mkdir -p "${ISO_DIR}"
    cd "${ISO_DIR}"

    BR_IP_NODE=$(config_vm_ip "${NAME}")
    SSH_PUBLIC_KEY=$(ssh_load_pubkey)
    export BR_IP_NODE
    export NAME
    export SSH_PUBLIC_KEY
    export NTP_POOLS=$(join_array ',' $NTP_POOLS)
    export NTP_SERVERS=$(join_array ',' $NTP_SERVERS)
    envsubst < "${TEMPLATE_DIR}/user-data.sub" > user-data

    if [[ ! -z "${ADDL_USERDATA}" ]]
    then
      echo >> user-data
      echo -e "${ADDL_USERDATA}" >> user-data
    fi

    envsubst < "${TEMPLATE_DIR}/meta-data.sub" > meta-data

    export DNS_SERVERS=$(join_array ',' $UPSTREAM_DNS)
    envsubst < "${TEMPLATE_DIR}/network-config.sub" > network-config

    {
        genisoimage \
            -V cidata \
            -input-charset utf-8 \
            -joliet \
            -rock \
            -o cidata.iso \
                meta-data \
                network-config \
                user-data

        virsh vol-create-as \
            --pool "${VIRSH_POOL}" \
            --name "cloud-init-${NAME}.iso" \
            --capacity "$(stat -c %s "${ISO_DIR}/cidata.iso")" \
            --format raw

        virsh vol-upload \
            --pool "${VIRSH_POOL}" \
            --vol "cloud-init-${NAME}.iso" \
            --file "${ISO_DIR}/cidata.iso"
    } &>> "${LOG_FILE}"
}

iso_path() {
    NAME=${1}
    echo "${TEMP_DIR}/iso/${NAME}/cidata.iso"
}

net_clean() {
    if virsh net-list --name | grep ^airship_gate$ > /dev/null; then
        log Destroying Airship gate network
        virsh net-destroy "${XML_DIR}/network.xml" &>> "${LOG_FILE}"
    fi
}

net_declare() {
    if ! virsh net-list --name | grep ^airship_gate$ > /dev/null; then
        log Creating Airship gate network
        virsh net-define "${XML_DIR}/network.xml" &>> "${LOG_FILE}"
        virsh net-start airship_gate
        virsh net-autostart airship_gate
    fi
}

pool_declare() {
    log Validating virsh pool setup
    if ! virsh pool-uuid "${VIRSH_POOL}" &> /dev/null; then
        log Creating pool "${VIRSH_POOL}"
        virsh pool-define-as --name "${VIRSH_POOL}" --type dir --target "${VIRSH_POOL_PATH}" &>> "${LOG_FILE}"
        virsh pool-start "${VIRSH_POOL}"
        virsh pool-autostart "${VIRSH_POOL}"
    fi
}

vm_clean() {
    NAME=${1}
    if virsh list --name | grep "${NAME}" &> /dev/null; then
        virsh destroy "${NAME}" &>> "${LOG_FILE}"
    fi

    if virsh list --name --all | grep "${NAME}" &> /dev/null; then
        log Removing VM "${NAME}"
        virsh undefine --remove-all-storage --domain "${NAME}" &>> "${LOG_FILE}"
    fi
}

vm_clean_all() {
    log Removing all VMs
    VM_NAMES=($(config_vm_names))
    for NAME in ${VM_NAMES[*]}
    do
        vm_clean "${NAME}"
    done
    wait
}

vm_create() {
    NAME=${1}
    MAC_ADDRESS=$(config_vm_mac "${NAME}")
    IO_PROF=$(config_vm_io "${NAME}")
    if [[ "$IO_PROF" == "fast" ]]
    then
      DISK_OPTS="bus=virtio,cache=none,format=qcow2,io=native"
    elif [[ "$IO_PROF" == "safe" ]]
    then
      DISK_OPTS="bus=virtio,cache=directsync,discard=unmap,format=qcow2,io=native"
    else
      DISK_OPTS="bus=virtio,format=qcow2"
    fi
    vol_create_root "${NAME}"
    wait

    if [[ "$(config_vm_bootstrap ${NAME})" == "true" ]]; then
        iso_gen "${NAME}" "$(config_vm_userdata ${NAME})"
        wait

        log Creating VM "${NAME}" and bootstrapping the boot drive
        virt-install \
            --name "${NAME}" \
            --virt-type kvm \
            --cpu ${VIRSH_CPU_OPTS} \
            --graphics vnc,listen=0.0.0.0 \
            --noautoconsole \
            --network "network=airship_gate,model=virtio" \
            --mac="${MAC_ADDRESS}" \
            --vcpus "$(config_vm_vcpus ${NAME})" \
            --memory "$(config_vm_memory ${NAME})" \
            --import \
            --disk "vol=${VIRSH_POOL}/airship-gate-${NAME}.img,${DISK_OPTS}" \
            --disk "vol=${VIRSH_POOL}/cloud-init-${NAME}.iso,device=cdrom" &>> "${LOG_FILE}"

        ssh_wait "${NAME}"
        ssh_cmd "${NAME}" cloud-init status --wait
        ssh_cmd "${NAME}" sync

    else
        log Creating VM "${NAME}"
        virt-install \
            --name "${NAME}" \
            --virt-type kvm \
            --cpu ${VIRSH_CPU_OPTS} \
            --graphics vnc,listen=0.0.0.0 \
            --noautoconsole \
            --network "network=airship_gate,model=virtio" \
            --mac="${MAC_ADDRESS}" \
            --vcpus "$(config_vm_vcpus ${NAME})" \
            --memory "$(config_vm_memory ${NAME})" \
            --import \
            --disk "vol=${VIRSH_POOL}/airship-gate-${NAME}.img,${DISK_OPTS}" &>> "${LOG_FILE}"
    fi
    virsh autostart "${NAME}"
}

vm_create_validate() {
    NAME=${1}
    vm_create "${name}"
    if [[ "$(config_vm_bootstrap ${name})" == "true" ]]
    then
      vm_validate "${name}"
    fi
}

vm_create_all() {
    log Starting all VMs

    VM_NAMES=($(config_vm_names))
    for name in ${VM_NAMES[*]}
    do
      vm_create_validate "${name}" &
    done
    wait
}

vm_start() {
    NAME=${1}
    log Starting VM "${NAME}"
    virsh start "${NAME}" &>> "${LOG_FILE}"
    ssh_wait "${NAME}"
}

vm_stop() {
    NAME=${1}
    log Stopping VM "${NAME}"
    virsh destroy "${NAME}" &>> "${LOG_FILE}"
}

vm_stop_non_genesis() {
    log Stopping all non-genesis VMs in parallel
    for NAME in $(config_non_genesis_vms); do
        vm_stop "${NAME}" &
    done
    wait
}

vm_restart_all() {
    for NAME in $(config_vm_names); do
        vm_stop "${NAME}" &
    done
    wait

    for NAME in $(config_vm_names); do
        vm_start "${NAME}" &
    done
    wait
}

vm_validate() {
    NAME=${1}
    if ! virsh list --name | grep "${NAME}" &> /dev/null; then
        log VM "${NAME}" did not start correctly.
        exit 1
    fi
}


vol_create_root() {
    NAME=${1}

    if virsh vol-list --pool "${VIRSH_POOL}" | grep "airship-gate-${NAME}.img" &> /dev/null; then
        log Deleting previous volume "airship-gate-${NAME}.img"
        virsh vol-delete --pool "${VIRSH_POOL}" "airship-gate-${NAME}.img" &>> "${LOG_FILE}"
    fi

    log Creating root volume for "${NAME}"
    if [[ "$(config_vm_bootstrap ${NAME})" == "true" ]]; then
        virsh vol-create-as \
            --pool "${VIRSH_POOL}" \
            --name "airship-gate-${NAME}.img" \
            --capacity 64G \
            --format qcow2 \
            --backing-vol 'airship-gate-base.img' \
            --backing-vol-format qcow2 &>> "${LOG_FILE}"
    else
        virsh vol-create-as \
            --pool "${VIRSH_POOL}" \
            --name "airship-gate-${NAME}.img" \
            --capacity 64G \
            --format qcow2 &>> "${LOG_FILE}"
    fi
}

#Find the correct group name for libvirt access
get_libvirt_group() {
    grep -oE '^libvirtd?:' /etc/group | tr -d ':'
}

# Make a user 'virtmgr' if it does not exist and add it to the libvirt group
make_virtmgr_account() {
    for libvirt_group in $(get_libvirt_group)
    do
        if [[ -z "$(grep -oE '^virtmgr:' /etc/passwd)" ]]
        then
            sudo useradd -m -s /bin/sh -g "${libvirt_group}" virtmgr
        else
            sudo usermod -g "${libvirt_group}" virtmgr
        fi
    done
}

# Generate a new keypair
gen_libvirt_key() {
    log Removing any existing virtmgr SSH keys
    sudo rm -rf ~virtmgr/.ssh
    sudo mkdir -p ~virtmgr/.ssh

    if [[ "${GATE_SSH_KEY}" ]]; then
        log "Using existing SSH keys for virtmgr"
        sudo cp "${GATE_SSH_KEY}" ~virtmgr/.ssh/airship_gate
        sudo cp "${GATE_SSH_KEY}.pub" ~virtmgr/.ssh/airship_gate.pub
    else
        log "Generating new SSH keypair for virtmgr"
        sudo ssh-keygen -N '' -b 2048 -t rsa -f ~virtmgr/.ssh/airship_gate &>> "${LOG_FILE}"
    fi
}

# Install private key into site definition
install_libvirt_key() {
    export PUB_KEY=$(sudo cat ~virtmgr/.ssh/airship_gate.pub)

    mkdir -p ${TEMP_DIR}/tmp
    envsubst < "${TEMPLATE_DIR}/authorized_keys.sub" > ${TEMP_DIR}/tmp/virtmgr.authorized_keys
    sudo cp ${TEMP_DIR}/tmp/virtmgr.authorized_keys ~virtmgr/.ssh/authorized_keys
    sudo chown -R virtmgr ~virtmgr/.ssh
    sudo chmod 700 ~virtmgr/.ssh
    sudo chmod 600 ~virtmgr/.ssh/authorized_keys

    if [[ "${USE_EXISTING_SECRETS}" ]]; then
        log "Using existing manifests for secrets"
	return 0
    fi

    mkdir -p "${GATE_DEPOT}"
    cat << EOF > ${GATE_DEPOT}/airship_drydock_kvm_ssh_key.yaml
---
schema: deckhand/CertificateKey/v1
metadata:
  schema: metadata/Document/v1
  name: airship_drydock_kvm_ssh_key
  layeringDefinition:
    layer: site
    abstract: false
  storagePolicy: cleartext
data: |-
EOF
    sudo cat ~virtmgr/.ssh/airship_gate | sed -e 's/^/  /' >> ${GATE_DEPOT}/airship_drydock_kvm_ssh_key.yaml
}
