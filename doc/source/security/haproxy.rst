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

.. _haproxy_security_guide:

HAProxy Security Guide
======================

Updated: 13-AUG-2018

This guide covers configurations for HAProxy.  Specifically, in ``mode tcp``.

.. contents:: :depth: 2

Security Item List
------------------

TCP Mode
^^^^^^^^

The instance will work in pure TCP mode. A full-duplex connection will be
established between clients and servers, and no layer 7 examination will be
performed. This is the default mode. It should be used for TLS.

Max Connections
^^^^^^^^^^^^^^^

Set ``maxconn`` in ``global`` to a reasonable level.  HAProxy will queue
requests beyond that value.

Set Headers
^^^^^^^^^^^
"set-header" does the same as "add-header" except that the header name is first
removed if it existed. This is useful when passing security information to the
server, where the header must not be manipulated by external users. Note that
the new value is computed before the removal so it is possible to concatenate a
value to an existing header.

References
----------

`HAProxy Configuration Guide <http://cbonte.github.io/haproxy-dconv/1.8/configuration.html>`_
