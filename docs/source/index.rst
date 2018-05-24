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

.. tip::

  The Undercloud Platform is part of the containerized Local Control Plane
  (cLCP). More details may be found by using the `Treasuremap`_

.. note::

  These documents will be reworked to reflect the changes associated with
  becoming an OpenStack hosted project: Airship. Expect major changes to occur
  with time. See more at `airshipit.org`_

Airship
=======

Airship is a collection of components that coordinate to form a means of
configuring, deploying and maintaining a `Kubernetes`_ environment using a
declarative set of `yaml`_ documents.

Approach
--------
Airship revolves around the setup and use of Kubernetes and `Helm`_ and takes
cues from these projects. The first use case of Airship is the deployment
of `OpenStack Helm`_ which also influences Airship's direction.

Building this Documentation
---------------------------

Use of ``sphinx-build -b html docs/source docs/build`` will build a html
version of this documentation that can be viewed using a browser at
docs/build/index.html on the local filesystem.

Conventions and Standards
-------------------------

.. toctree::
   :maxdepth: 3

   conventions
   blueprints/blueprints


.. _airshipit.org: https://airshipit.org
.. _Helm: https://helm.sh/
.. _Kubernetes: https://kubernetes.io/
.. _Openstack: https://www.openstack.org/
.. _Openstack Helm: https://github.com/openstack/openstack-helm
.. _Treasuremap: https://github.com/att-comdev/treasuremap
.. _yaml: http://yaml.org/
