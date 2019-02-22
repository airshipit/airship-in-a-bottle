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

.. _security_guide:

Airship Security Guide
======================

An undercloud environment deployed via Airship crosses many security domains. This
guide explains many of the security concerns that have been reviewed and considered
by the Airship developers. Because Airship is a highly configuration-driven platform,
there is some onus on the end-user to make good decisions with their configuration.

Layout and Nomenclature
-----------------------

Each topic in the security guide will provide some overview for scope of that topic
and then provide a list of tactical security items. For each item two statuses will
be listed as well as the project scope.

  * Project Scope: Which Airship projects address this security item.
  * Solution: The solution is how this security concern is addressed in the platform

    * Remediated: The item is solved for automatically
    * Configurable: The item is based on configuration. Guidance will be provided.
    * Mitigated: The item currently mitigated while a permanent remediation is in progress.
    * Pending: Addressing the item is in-progress

  * Audit: Auditing the item provides for ongoing monitoring to ensure there is no regression

    * Testing: The item is tested for in an automated test pipeline during development
    * Validation: The item is reported on by a validation framework after a site deployment
    * Pending: Auditing is in-progress

Airship Security Topics
-----------------------

.. toctree::
  :maxdepth: 1

  template
  haproxy
  ubuntu
