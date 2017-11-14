..
      Copyright 2017 AT&T Intellectual Property.
      All Rights Reserved.

      Licensed under the Apache License, Version 2.0 (the "License"); you may
      not use this file except in compliance with the License. You may obtain
      a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
      License for the specific language governing permissions and limitations
      under the License.

.. _ucp-basic-deployment:

Deployment Guide
----------------

.. note::
  The Undercloud Platform is still under active development and this
  guide will evolve along the way

The current deployment makes use of the `ucp-integration`_ repository to set up
the underlaying Kubernetes infrastructure, Ceph and UCP components. This
approach sets up an 'All-In-One' UCP environment that allows developers to
bring up the UCP components on a single Ubuntu 16.04 Virtual Machine.

.. note::

  Note that the minimum recommended size of the VM is 4 vCPUs, 16GB of RAM with
  64GB disk space


Pre-Deployment Preparations
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. todo::
  Update these to use env vars as input to the UCP basic process instead of
  sed.

1. Set up `etc/hosts` on a freshly installed Ubuntu 16.04 Virtual Machine such
   that the local IP address is referenced by the hostname.

   E.g. `127.0.0.1 host1`

::

   HOST_IFACE=$(ip route | grep "^default" | head -1 | awk '{ print $5 }')
   LOCAL_IP=$(ip addr | awk "/inet/ && /${HOST_IFACE}/{sub(/\/.*$/,\"\",\$2); print \$2}")
   cat << EOF | sudo tee -a /etc/hosts
   ${LOCAL_IP} $(hostname)
   EOF

2. Clone the `ucp-integration` repository.
::

   git clone https://github.com/att-comdev/ucp-integration.git


Deployment
~~~~~~~~~~

This deploys UCP in a production-like mode using the basic_ucp deployment.
Setup for specific components in a development mode may require some additional
setup prior to these steps.

1. Switch to root user after performing the steps in the `Pre-Deployment
   Preparations`_ section.

::

   sudo -i
   cd /home/ubuntu/ucp-integration/manifests/basic_ucp/

2. Source the set-env.sh script

::

   source set-env.sh

3. Export/override the variables that are unique to the environment. For
   instance, we can do the following to update the environment variables for a
   VM that is assigned an IP of `30.30.30.4` on interface `ens3`
   (network `30.30.30.0/24`):

::

   export CEPH_CLUSTER_NET=30.30.30.0/24
   export CEPH_PUBLIC_NET=30.30.30.0/24
   export GENESIS_NODE_IP=30.30.30.4
   export NODE_NET_IFACE=ens3
   export GENESIS_NODE_NAME=$(hostname)

.. note::

  These may be overridden directly in the set-env.sh instead of
  exporting these as a separate step.

4. Start the UCP deployment

::

   ./deploy_ucp.sh

Post Deployment
~~~~~~~~~~~~~~~

1. The deployment is fully automated and can take a while to complete (it can
   take 30 minutes to an hour for a full deployment to complete)

2. The environment should resemble the following after executing the required
   steps:

::

   # sudo kubectl get pods -n ucp
   NAME                                   READY     STATUS    RESTARTS   AGE
   airflow-flower-6cdc6f9cb4-5r62v        1/1       Running   0          3h
   airflow-scheduler-6d54445bf8-6ldrd     1/1       Running   0          3h
   airflow-web-7bd69d857d-qlptj           1/1       Running   0          3h
   airflow-worker-666696d6c5-vffpg        1/1       Running   0          3h
   armada-api-84df5b7fc9-4nxp5            1/1       Running   0          4h
   barbican-api-85c956c84f-p4q7h          1/1       Running   0          4h
   deckhand-5468d59455-2mcqd              1/1       Running   0          4h
   drydock-api-f9897cf44-csbc8            1/1       Running   0          4h
   drydock-api-f9897cf44-jgv4q            1/1       Running   0          4h
   etcd-5bcbbd679c-rb5rf                  1/1       Running   0          4h
   ingress-api-xvkzx                      1/1       Running   0          4h
   ingress-error-pages-5d79688f6c-9b8xc   1/1       Running   0          4h
   keystone-api-6bc85c98-886mg            1/1       Running   0          4h
   maas-rack-5d4b84c4d5-dt87j             1/1       Running   0          4h
   maas-region-0                          1/1       Running   0          4h
   mariadb-0                              1/1       Running   0          4h
   mariadb-1                              1/1       Running   0          4h
   mariadb-2                              1/1       Running   0          4h
   memcached-5bf49657db-kq6qh             1/1       Running   0          4h
   postgresql-0                           1/1       Running   0          4h
   rabbitmq-f68649644-pnw6p               1/1       Running   0          4h
   shipyard-6f4c7765d-n2kx6               1/1       Running   0          3h

To check that all relevant helm charts have been deployed:

::

   # sudo helm ls
   NAME                                    REVISION        UPDATED                         STATUS          CHART                           NAMESPACE
   ucp-armada                              1               Fri Dec  1 10:03:44 2017        DEPLOYED        armada-0.1.0                    ucp
   ucp-barbican                            1               Fri Dec  1 10:03:47 2017        DEPLOYED        barbican-0.1.0                  ucp
   ucp-calico                              1               Fri Dec  1 10:00:05 2017        DEPLOYED        calico-0.1.0                    kube-system
   ucp-calico-etcd                         1               Fri Dec  1 09:59:28 2017        DEPLOYED        etcd-0.1.0                      kube-system
   ucp-ceph                                1               Fri Dec  1 10:00:58 2017        DEPLOYED        ceph-0.1.0                      ceph
   ucp-coredns                             1               Fri Dec  1 10:00:26 2017        DEPLOYED        coredns-0.1.0                   kube-system
   ucp-deckhand                            1               Fri Dec  1 10:03:39 2017        DEPLOYED        deckhand-0.1.0                  ucp
   ucp-drydock                             1               Fri Dec  1 10:03:37 2017        DEPLOYED        drydock-0.1.0                   ucp
   ucp-etcd-rabbitmq                       1               Fri Dec  1 10:02:44 2017        DEPLOYED        etcd-0.1.0                      ucp
   ucp-ingress                             1               Fri Dec  1 10:02:45 2017        DEPLOYED        ingress-0.1.0                   ucp
   ucp-keystone                            1               Fri Dec  1 10:03:45 2017        DEPLOYED        keystone-0.1.0                  ucp
   ucp-kubernetes-apiserver                1               Fri Dec  1 10:00:32 2017        DEPLOYED        apiserver-0.1.0                 kube-system
   ucp-kubernetes-controller-manager       1               Fri Dec  1 10:00:33 2017        DEPLOYED        controller_manager-0.1.0        kube-system
   ucp-kubernetes-etcd                     1               Fri Dec  1 10:00:31 2017        DEPLOYED        etcd-0.1.0                      kube-system
   ucp-kubernetes-proxy                    1               Fri Dec  1 09:58:46 2017        DEPLOYED        proxy-0.1.0                     kube-system
   ucp-kubernetes-scheduler                1               Fri Dec  1 10:00:34 2017        DEPLOYED        scheduler-0.1.0                 kube-system
   ucp-maas                                1               Fri Dec  1 10:03:36 2017        DEPLOYED        maas-0.1.0                      ucp
   ucp-maas-postgresql                     1               Fri Dec  1 10:02:44 2017        DEPLOYED        postgresql-0.1.0                ucp
   ucp-rabbitmq                            1               Fri Dec  1 10:02:45 2017        DEPLOYED        rabbitmq-0.1.0                  ucp
   ucp-rbac                                1               Fri Dec  1 10:00:44 2017        DEPLOYED        rbac-0.1.0                      kube-system
   ucp-shipyard                            1               Fri Dec  1 10:38:08 2017        DEPLOYED        shipyard-0.1.0                  ucp
   ucp-ucp-ceph-config                     1               Fri Dec  1 10:02:40 2017        DEPLOYED        ceph-0.1.0                      ucp
   ucp-ucp-mariadb                         1               Fri Dec  1 10:02:43 2017        DEPLOYED        mariadb-0.1.0                   ucp
   ucp-ucp-memcached                       1               Fri Dec  1 10:02:44 2017        DEPLOYED        memcached-0.1.0                 ucp

.. _ucp-integration: https://github.com/att-comdev/ucp-integration