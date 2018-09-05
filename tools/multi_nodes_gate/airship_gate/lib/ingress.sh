DNS_ZONE_FILE="${TEMP_DIR}/ingress.dns"
COREFILE="${TEMP_DIR}/ingress.corefile"

ingress_dns_config() {
  ingress_domain=$(config_ingress_domain)

  INGRESS_DOMAIN=${ingress_domain} envsubst '${INGRESS_DOMAIN}' < "${TEMPLATE_DIR}/ingress_header.sub" > "${DNS_ZONE_FILE}"

  read -a ingress_ip_list <<< $(config_ingress_ips)

  for ip in "${ingress_ip_list[@]}"
  do
    read -a ip_entries <<< $(config_ingress_entries $ip)
    for entry in "${ip_entries[@]}"
    do
      HOSTNAME=${entry} HOSTIP=${ip} envsubst < "${TEMPLATE_DIR}/ingress_entry.sub" >> "${DNS_ZONE_FILE}"
    done
  done

  DNS_DOMAIN=${ingress_domain} ZONE_FILE=$(basename $DNS_ZONE_FILE) envsubst < "${TEMPLATE_DIR}/ingress_corefile.sub" > "${COREFILE}"
}

ingress_dns_start() {
  # nodename where DNS should run
  nodename=$1
  remote_work_dir="/var/tmp/coredns"

  remote_zone_file="${remote_work_dir}/$(basename $DNS_ZONE_FILE)"
  remote_corefile="${remote_work_dir}/$(basename $COREFILE)"
  ssh_cmd "${nodename}" mkdir -p "${remote_work_dir}"
  rsync_cmd "$DNS_ZONE_FILE" "${nodename}:${remote_zone_file}"
  rsync_cmd "$COREFILE" "${nodename}:${remote_corefile}"
  ssh_cmd "${nodename}" docker run -d -v /var/tmp/coredns:/data -w /data --network host -P $IMAGE_COREDNS -conf $(basename $remote_corefile)
}
