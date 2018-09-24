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

.. _dev-getting-started:

Getting Started for Airship Developers
======================================
Airship uses many foundational concepts that should be understood by developers
wanting to get started. This documentation attempts to provide a survey of
those topics.

Concepts
--------

- Containers/Docker
- RESTful APIs
- YAML
- Security

Containers/Docker
~~~~~~~~~~~~~~~~~
Airship is, at its core, intended to be used in a containerized fashion.
Dockerfile resources exist in each of the project repositories that are used by
the build process to generate Docker images. Images are hosted on `quay.io`_
under ``airshipit``.

Each main component is responsible for generating one or more images (E.g.:
Shipyard produces a Shipyard image and an `Airflow`_ image).

When running, nearly every aspect of Airship runs as a container, and Airship
(primarily Promenade + Armada) sets up many of the other foundational
components as containers, including many `Kubernetes`_ components, `etcd`_,
`Calico`_, and `Ceph`_.

RESTful APIs
~~~~~~~~~~~~
Each Airship component that runs as a service provides a RESTful API.
Some :ref:`api-conventions` exist explaining the basic format of requests and
responses and required endpoints that are exposed, such as health check and
and design validation.

YAML
~~~~
The `YAML`_ document format is used along with `JSON Schema`_ to define the
declarative site and software design inputs to the Airship components.

Security
~~~~~~~~
Security is a consideration from the ground-up for Airship components. Some
technologies in this space are TLS and `Keystone`_ auth. Airship APIs are
protected by RBAC policies implemented with `oslo.policy`_ (with some
exceptions for basic health checking and listing of API versions). Keystone
middleware serves as a layer in the pipeline of service layers for each
component, providing lookup of authenticated users, resolving their roles,
which are then checked. Access enforcement is within the Airship components,
using a decorator for each API that requires limited access.

Environment
-----------

- Helm
- Kubernetes
- Linux

Helm
~~~~
Airship components are deployed into Kubernetes using `Armada`_, which in turn
uses the Tiller component of `Helm`_. Helm charts are used to generate the
Kubernetes artifacts (deployments, jobs, configmaps, etc...).

Kubernetes
~~~~~~~~~~
Airship is thoroughly intertwined with Kubernetes:

- Airship depends on Kubernetes as the orchestrator of the containers that make
  up the platform.
- Airship sets up a single node Kubernetes instance during the `Promenade`_
  genesis process, with the necessary configuration to become the seed of a
  resilient Kubernetes cluster during later stages of Airship.
- Airship's components run as containers inside the Kubernetes cluster.

Linux
~~~~~
Airship is targeted to a Linux platform. There are significant elements of
Airship that use shell scripts to drive processes.

Coding
------
Further information is available in :ref:`code-conventions`.

Airship is primarily a combination of Python 3 and shell scripting. There are
several Python libraries that are used in common across many components:

- Falcon: A service framework providing the API endpoints.
- uWSGI: The service container.
- oslo_config: Provides per-deployment, configuration file configurability.
- oslo_policy: Provides RBAC support for API endpoints (and more).
- Requests: A framework for making HTTP requests and receiving responses.
- Click: A CLI framework used to provide component-level Command Line
  Interfaces.

Each component also brings in their own dependencies as needed.

Database(s)
-----------
Several of the Airship components require some data persistence. Some data
persistence is achieved by utilizing Kubernetes provided mechanisms, and the
Keystone software uses a MariaDB instance, but most is accomplished using a
containerized PostgreSQL database.

Interaction with PostgreSQL uses the following:

- SQLAlchemy: A python library providing most of the needed database
  functionality.
- Alembic: Version management for database schemas and data.
- oslo_db: An OpenStack layer providing additional functionality over
  SQLAlchemy.

Testing
-------

- Unit
- Functional
- Integration

Unit and functional tests are used in the gating of changes before merging
code. Unit tests utilize combinations of `pytest`_ and `stestr`_. Functional
tests utilize `Gabbi`_. These tools are not exclusive of others, but are the
primary tools being used for unit and functional tests.

Integration testing is orchestrated in the merge gates, and uses various means
of testing.

.. _Airflow: https://airflow.apache.org/
.. _Armada: https://airship-armada.readthedocs.io/
.. _Calico: https://www.projectcalico.org/calico-networking-for-kubernetes/
.. _Ceph: https://ceph.com
.. _etcd: https://coreos.com/etcd/
.. _Gabbi: https://github.com/cdent/gabbi
.. _Helm: https://github.com/kubernetes/helm
.. _JSON Schema: http://json-schema.org/
.. _Keystone: https://docs.openstack.org/keystone/latest/
.. _Kubernetes: https://kubernetes.io/
.. _oslo.policy: https://docs.openstack.org/oslo.policy/latest/
.. _Promenade: https://airship-promenade.readthedocs.io/
.. _pytest: https://docs.pytest.org/en/latest/
.. _quay.io: https://quay.io/organization/airshipit
.. _stestr: https://github.com/mtreinish/stestr
.. _YAML: http://yaml.org/
