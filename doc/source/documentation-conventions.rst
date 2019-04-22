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

.. _documentation-conventions:

Documentation
=============
Each Airship component will maintain documentation addressing two audiences:

  #. Consumer documentation
  #. Developer documentation

Consumer Documentation
----------------------
Consumer documentation is that which is intended to be referenced by users of
the component. This includes information about each of the following:

-  Introduction - the purpose and charter of the software
-  Features - capabilies the software has
-  Usage - interaction with the software - e.g. API and CLI documentation
-  Setup/Installation - how an end user would set up and run the software
   including system requirements
-  Support - where and how a user engages support or makes change requests for
   the software

Developer Documentation
-----------------------
Developer documentation is used by developers of the software, and addresses
the following topics:

-  Archiecture and Design - features and structure of the software
-  Inline, Code, Method - documentaiton specific to the fuctions and procedures
   in the code
-  Development Environment - explaining how a developer would need to configure
   a working environment for the software
-  Contribution - how a developer can contribute to the software

Format
------
There are multiple means by which consumers and developers will read the
documentation for Airship components. The two common places for Airship
components are `Github`_ in the form of README and code-based documentation,
and `Readthedocs`_ for more complete/formatted documentation.

Documentation that is expected to be read in Github must exist and may use
either `reStructuredText`_ or `Markdown`_. This generally would be limited to
the README file at the root of the project and/or a documentation directory.
The README should direct users to the published documentation location.

Documentation intended for Readthedocs will use reStructuredText, and should
provide a `Sphinx`_ build of the documentation.

Finding Treasuremap
-------------------
`Treasuremap`_ is a project that serves as a starting point for the larger
Containerized Cloud Platform, and provides context for the Airship component
projects.

Airship component projects should include the following at the top of the
main/index page of their `Readthedocs`_ documentation:

.. tip::

  {{component name}} is part of Airship, a collection of components that
  coordinate to form a means of configuring, deploying and maintaining a
  Kubernetes environment using a declarative set of yaml documents. More
  details on using Airship may be found by using the `Treasuremap`_

.. _reStructuredText: http://www.sphinx-doc.org/en/stable/rest.html
.. _Markdown: https://daringfireball.net/projects/markdown/syntax
.. _Readthedocs: https://airshipit.readthedocs.io/
.. _Github: https://github.com
.. _Sphinx: http://www.sphinx-doc.org/en/stable/index.html
.. _Treasuremap: https://opendev.org/airship/treasuremap/
