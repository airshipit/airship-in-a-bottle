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

.. _code-conventions:

Code and Project Conventions
============================

Conventions and standards that guide the development and arrangement of Airship
component projects.

Project Structure
-----------------

Charts
~~~~~~
Each project that maintains helm charts will keep those charts in a directory
``charts`` located at the root of the project. The charts directory will
contain subdirectories for each of the charts maintained as part of that
project. These subdirectories should be named for the component represented by
that chart.

e.g.: For project ``foo``, which also maintains the charts for ``bar`` and
``baz``:

-  foo/charts/foo contains the chart for ``foo``
-  foo/charts/bar contains the chart for ``bar``
-  foo/charts/baz contains the chart for ``baz``

Helm charts utilize the `helm-toolkit`_ supported by the `Openstack-Helm`_ team
and follow the standards documented there.

Images
~~~~~~
Each project that creates a `Docker`_ image will keep the dockerfile in a
directory ``images`` located at the root of the project. The images directory
will contain subdirectories for each of the images created as part of that
project. The subdirectory will contain the dockerfile that can be used to
generate the image.

e.g.: For project ``foo``, which also produces a Docker image for ``bar``:

-  foo/images/foo contains the dockerfile for ``foo``
-  foo/images/bar contains the dockerfile for ``bar``

Makefile
~~~~~~~~
Each project must provide a makefile at the root of the project. The makefile
should implement each of the following makefile targets:

-  ``images`` will produce the docker images for the component and each other
   component it is responsible for building.
-  ``charts`` will helm package all of the charts maintained as part of the
   project.
-  ``lint`` will perform code linting for the code and chart linting for the
   charts maintained as part of the project, as well as any other reasonable
   linting activity.
-  ``dry-run`` will produce a helm template for the charts maintained as part
   of the project.
-  ``all`` will run the lint, charts, and images targets.
-  ``docs`` should render any documentation that has build steps.
-  ``run_{component_name}`` should build the image and do a rudimentary (at
   least) test of the image's functionality.
-  ``run_images`` performs the inidividual run_{component_name} targets for
   projects that produce more than one image.
-  ``tests`` to invoke linting tests (e.g. PEP-8) and unit tests for the
   components in the project

For projects that are Python based, the makefile targets typically reference
tox commands, and those projects will include a tox.ini defining the tox
targets. Note that tox.ini files will reside inside the source directories for
modules within the project, but a top-level tox.ini may exist at the root of
the repository that includes the necessary targets to build documentation.

Documentation
~~~~~~~~~~~~~
Also see :ref:`documentation-conventions`

Documentation source for the component should reside in a 'docs' directory at
the root of the project.

Linting and Formatting Standards
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Code in the Airship components should follow the prevalent linting and
formatting standards for the language being implemented.  In lieu of industry
accepted code formatting standards for a target language, strive for
readability and maintainability.

===============  ======================================
Known Standards
-------------------------------------------------------
Language         Uses
===============  ======================================
Python           PEP-8
===============  ======================================

Airship components must provide for automated checking of their formatting
standards, such as the lint step noted above in the makefile. Components may
provide automated reformatting.

Tests Location
~~~~~~~~~~~~~~
Tests should be in parallel structures to the related code, unless dictated by
target language ecosystem.

For Python projects, the preferred location for tests is a ``tests`` directory
under the directory for the module. E.g. Tests for module foo:
{root}/src/bin/foo/foo/tests.
An alternataive location is ``tests`` at the root of the project, although this
should only be used if there are not multiple components represented in the
same repository, or if the tests cross the components in the repository.

Each type of test should be in its own subdirectory of tests, to allow for easy
separation.  E.g. tests/unit, tests/functional, tests/integration.

Source Code Location
~~~~~~~~~~~~~~~~~~~~
A standard structure for the source code places the source for each module in
a module-named directory under either /src/bin or /src/lib, for executable
modules and shared library modules respectively. Since each module needs its
own setup.py and setup.cfg (python) that lives parallel to the top-level
module (i.e. the package), the directory for the module will contain another
directory named the same.

For example, Project foo, with module foo_service would have a source structure
that is /src/bin/foo_service/foo_service, wherein the __init__.py for the
package resides.

Sample Project Structure (Python)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Project ``foo``, supporting multiple executable modules ``foo_service``,
``foo_cli``, and a shared module ``foo_client`` ::

  {root of foo}
   |- /doc
   |    |- /source
   |    |- requirements.txt
   |- /etc
   |    |- /foo
   |         |- {sample files}
   |- /charts
   |    |- /foo
   |    |- /bar
   |- /images
   |    |- /foo
   |    |    |- Dockerfile
   |    |- /bar
   |         |- Dockerfile
   |- /tools
   |    |- {scripts/utilities supporting build and test}
   |- /src
   |    |- /bin
   |    |    |- /foo_service
   |    |    |    |- /foo_service
   |    |    |    |    |- __init__.py
   |    |    |    |    |- {source directories and files}
   |    |    |    |- /tests
   |    |    |    |    |- unit
   |    |    |    |    |- functional
   |    |    |    |- setup.py
   |    |    |    |- setup.cfg
   |    |    |    |- requirements.txt (and related files)
   |    |    |    |- tox.ini
   |    |    |- /foo_cli
   |    |         |- /foo_cli
   |    |         |    |- __init__.py
   |    |         |    |- {source directories and files}
   |    |         |- /tests
   |    |         |    |- unit
   |    |         |    |- functional
   |    |         |- setup.py
   |    |         |- setup.cfg
   |    |         |- requirements.txt (and related files)
   |    |         |- tox.ini
   |    |- /lib
   |         |- /foo_client
   |              |- /foo_client
   |              |    |- __init__.py
   |              |    |- {source directories and files}
   |              |- /tests
   |              |    |- unit
   |              |    |- functional
   |              |- setup.py
   |              |- setup.cfg
   |              |- requirements.txt (and related files)
   |              |- tox.ini
   |- Makefile
   |- README  (suitable for github consumption)
   |- tox.ini (primarily for the build of repository-level docs)

Note that this is a sample structure, and that target languages may preclude
the location of some items (e.g. tests). For those components with language
or ecosystem standards contrary to this structure, ecosystem convention should
prevail.


.. _Docker: https://www.docker.com/
.. _helm-toolkit: https://git.openstack.org/cgit/openstack/openstack-helm-infra/tree/helm-toolkit
.. _Openstack-Helm: https://wiki.openstack.org/wiki/Openstack-helm
