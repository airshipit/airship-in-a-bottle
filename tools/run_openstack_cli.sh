#!/bin/bash
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

set -e

# Define variables
COMMAND='openstack'
OPENSTACK_CLI_IMAGE="${OPENSTACK_CLI_IMAGE:-docker.io/openstackhelm/heat:newton}"

# Get the path of the directory where the script is located
# Source Base Docker Command
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${DIR} && source openstack_cli_docker_base_command.sh

# Execute OpenStack CLI
${base_docker_command} ${OPENSTACK_CLI_IMAGE} ${COMMAND} $@
