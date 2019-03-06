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

.. _template_security_guide:

Template for a Security Guide Topic
===================================

Updated: 1-AUG-2018

An overview of the scope of this topic.

.. contents:: :depth: 2

Security Item List
------------------

Sensitive Data Security
^^^^^^^^^^^^^^^^^^^^^^^

Sensitive data should be encrypted at-rest.

  * Project Scope: Deckhand
  * Solution *Remediated*: The ``storagePolicy`` metadata determines if Deckhand will persist
    document data encrypted.
  * Audit: *Testing*: Pipeline test checks that documents with a ``storagePolicy: encrypted``
    are not persisted to the database with an intact ``data`` section.

Sensitive data should be encrypted in-transit.

  * Project Scope: Shipyard, Deckhand
  * Solution *Pending*: Shipyard and Deckhand API endpoints should support
    TLS. See data_security_.
  * Audit: *Pending*: Expect to validate post-deployment that endpoints all support TLS

Configuration Guidance
----------------------

For items that require guidance on configuration that impact a security item
please list an item here. Use RST anchors and links to link the security item solution
status to this guidance.

Temporary Mitigation Status
---------------------------

.. _data_security:

Data Security In-Transit
^^^^^^^^^^^^^^^^^^^^^^^^

Current work to support Deckhand enabling TLS termination, Shipyard enabling self-signing
CAs and Barbican supporting TLS termination.

References
----------

`Transport Layer Security (TLS) <https://www.sans.org/reading-room/whitepapers/protocols/ssl-tls-beginners-guide-1029>`_
