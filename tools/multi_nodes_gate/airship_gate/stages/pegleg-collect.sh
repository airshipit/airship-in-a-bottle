#!/usr/bin/env bash
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

set -xe

source "${GATE_UTILS}"

mkdir -p "${DEFINITION_DEPOT}"
chmod 777 "${DEFINITION_DEPOT}"

render_pegleg_cli() {
    cli_string="pegleg -v site"

    primary_repo=$(config_pegleg_primary_repo)

    if [[ -d "${REPO_ROOT}/${primary_repo}" ]]
    then
      cli_string="${cli_string} -p /workspace/${primary_repo}"
    else
      log "${primary_repo} not a valid primary repository"
      return 1
    fi

    aux_repos=($(config_pegleg_aux_repos))

    if [[ ${#aux_repos[@]} -gt 0 ]]
    then
        for r in ${aux_repos[*]}
        do
          cli_string="${cli_string} -a ${r}"
        done
    fi

    cli_string="${cli_string} collect -s /collect"

    cli_string="${cli_string} $(config_pegleg_sitename)"

    echo ${cli_string}
}

log "Collecting site definition to ${DEFINITION_DEPOT}"

docker run \
  --rm -t \
  --network none \
  -v "${REPO_ROOT}":/workspace \
  -v "${DEFINITION_DEPOT}":/collect \
  "${IMAGE_PEGLEG_CLI}" \
  $(render_pegleg_cli)

log "Generating virtmgr key documents"
gen_libvirt_key && install_libvirt_key
collect_ssh_key
