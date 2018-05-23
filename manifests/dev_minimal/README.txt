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

dev_minimal
===========

Sets up and deploys an instance of Airship using the images pinned in the
versions file of the targeted deployment_files based site definitions (dev).
versions file: deployment_files/global/v1.0dev/software/config/versions.yaml

Running ../common/deploy_airship.sh will download and build into the
/root/deploy directory.

Process
-------
1) Set up a VM with at least 4 cores and 12GB of memeory. 8 core/16GB is
   recommended. 32GB of disk is enough, use more if you plan on doing any
   extended use.
2) Become root. All the commands are run as root.
3) Update etc/hosts with IP/Hostname of your VM. e.g. 10.0.0.15 testvm1
4) go to /root/deploy and clone airship-in-a-bottle. Switch to a target
   patchset if needed
   4a) If you use a directory other than /root/deploy, /root/deploy will be
       created, and airship-in-a-bottle will be re-cloned there. (Technically
       /root/${WORKSPACE})
5) cd into /root/deploy/airship-in-a-bottle/manifests/dev_minimal
6) Update the set-env.sh with the hostname and ip on the appropriate lines.
7) source set-env.sh

NOTE: If running this behind a corporate proxy, you will need to update the
      file deployment_files/site/dev-proxy/networks/common-addresses.yaml to
      specify your proxy server and appropriate no_proxy list. Also change
      set-env.sh to use TARGET_SITE of 'dev-proxy'.

8) ../common/deploy-airship.sh
You may sepecify a target point to stop the deployment by using an argument of
"collect", "genesis", or "deploy" to the deploy_airship.sh. It will
default to "genesis".  The "demo" value that is supported will not work with
the dev_minimal site definition.

Next Steps
----------
Assuming a target breakpoint of "genesis" or "deploy", all of the documents
used for a subsequent deploy_site action are now placed into the
/root/deploy/site directory for ease of use - instructions are
provided by the script at the end of a successful genesis process.

A script: "creds.sh" is copied into the /root/deploy/site
directory that can be sourced to set environment variables that will enable
Keystone authorization to use for running Shipyard.

Example:

. creds.sh

Other files located in /root/deploy/site:
run_shipyard.sh - runs a container to execute the CLI for Shipyard
certificates.yaml - the certificates generated automatically during this
    deployment
deployment_files.yaml - the files used during a deploy_site or update_site
    action in Shipyard.

Example:

cd /root/deploy/site
. creds.sh
./run_shipyard.sh create configdocs design --filename=/home/shipyard/host/deployment_files.yaml
./run_shipyard.sh create configdocs secrets --filename=/home/shipyard/host/certificates.yaml --append
./run_shipyard.sh commit configdocs

Optionally, if you wish to deploy the loaded configdocs:

./run_shipyard.sh create action deploy_site
