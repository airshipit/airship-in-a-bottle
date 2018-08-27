..
      Copyright 2018 AT&T Intellectual Property.
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

.. _gates:

Gates
=====
Airship-in-a-bottle contains the multi_node_gates utility to aid developers
and automation of Airship.  These tools are found in tools/multi_node_gates.

Setup and Use
-------------

1. First time, and only needed once per node, ./setup_gate.sh will prepare the
   node for use by setting up the necessary users, virsh and some dependencies.
2. gate.sh is the starting point to run each of the named gates, found in
   ./airship_gate/manifests, e.g.::

     $ ./gate.sh multinode_genesis

   where the argument for the gate.sh script is the filename of the json file
   in ./airship_gate/manifests without the json extension.

Each of the defined manifests used for the gate defines a virtual machine
configuration, and the steps to run as part of that gate. Additional
information found in each file is a configuration that targets a particular
set of Airship site configurations, which in some of the provided manifests are
found in the deployment_files/site directory.

Other Utilities
---------------
Several useful utilities are found in ./airship_gate/bin to facilitate
interactions with the VMs created. These commands are effectively wrapped
scripts providing the functionality of the utility they wrap, but also
incorporating the necessary identifying information needed for a particular
run of a gate. E.g.::

  $ ./airship_gate/bin/ssh.sh n0
