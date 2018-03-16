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

# Credentials that can be exported to work with Shipyard.
# Note that if the password was changed before the deployment, it will need to
# be changed to match here.
# To set your environment variables to the values in this script, run using:
# source creds.sh
#
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_DOMAIN_NAME=default
export OS_PROJECT_NAME=service
export OS_USERNAME=shipyard
export OS_PASSWORD=password18
export OS_AUTH_URL=http://keystone.ucp.svc.cluster.local:80/v3