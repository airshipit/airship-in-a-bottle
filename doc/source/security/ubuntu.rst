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

.. _ubuntu_security_guide:

Canonical Ubuntu/MAAS Security Guide
====================================

Updated: 6-AUG-2018

This guide covers the configuration of MAAS to run securely and to deploy
secure installations of Ubuntu 16.04.x. Some items are above and beyond MAAS
when MAAS does not offer the functionality needed to fully secure a
newly provisioned server.

.. contents:: :depth: 2

Security Item List
------------------

Filesystem Permissions
^^^^^^^^^^^^^^^^^^^^^^

Many files on the filesystem can contain sensitive data that can hasten a malignant
attack on a host. Ensure the below files have appropriate ownership and permissions

================================== ========= ========= ===============
  Filesystem Path                    Owner     Group     Permissions
================================== ========= ========= ===============
``/boot/System.map-*``               root      root      ``0600``
``/etc/shadow``                      root      shadow    ``0640``
``/etc/gshadow``                     root      shadow    ``0640``
``/etc/passwwd``                     root      root      ``0644``
``/etc/group``                       root      root      ``0644``
``/var/log/kern.log``                root      root      ``0640``
``/var/log/auth.log``                root      root      ``0640``
``/var/log/syslog``                  root      root      ``0640``
================================== ========= ========= ===============

  - Project Scope: Drydock
  - Solution *Configurable*: A bootaction will be run to enforce this on first boot
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin

Filesystem Partitioning
^^^^^^^^^^^^^^^^^^^^^^^

The mounts ``/tmp``, ``/var``, ``/var/log``, ``/var/log/audit`` and ``/home`` should be
individual file systems.

  - Project Scope: Drydock
  - Solution *Configurable*: Drydock supports user designed partitioning, see
    `Filesystem Configuration`_.
  - Audit: *Testing*: The Airship testing pipeline will validate that nodes are partitioned
    as described in the site definition.

Filesystem Hardening
^^^^^^^^^^^^^^^^^^^^

Disallow symlinks and hardlinks to files not owned by the user. Set ``fs.protected_symlinks`` and
``fs.protected_hardlinks`` to ``1``.

  - Project Scope: Diving Bell
  - Solution *Configurable*: Diving Bell overrides will enforce this kernel tunable. By default
    MAAS deploys nodes in compliance.
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin.

Execution Environment Hardening
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The kernel tunable ``fs.suid_dumpable`` must be set to ``0`` and there must be a hard limit
disabling core dumps (``hard core 0``)

  - Project Scope: DivingBell, Drydock
  - Solution *Configurable*: Diving Bell overrides will enforce this kernel tunable, by default
    MAAS deploys nodes with ``fs.suid_dumpable = 2``. A boot action will put in place the hard
    limit.
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin

Randomizing stack space can make it harder to exploit buffer overflow vulnerabilities. Enable
the kernel tunable ``kernel.randomize_va_space = 2``.

  - Project Scope: DivingBell
  - Solution *Configurable*: Diving Bell overrides will enforce this kernel tunable, by default
    MAAS deploys nodes in compliance.
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin

Mandatory Access Control
^^^^^^^^^^^^^^^^^^^^^^^^

Put in place the approved default AppArmor profile and ensure that Docker is configured
to use it.

  - Project Scope: Drydock, Promenade
  - Solution *Configurable*: A bootaction will put in place the default AppArmor profile. Promenade
    will deploy a Docker configuration to enforce the default policy.
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin probing
    ``/proc/<pid>/attr/current``.

Put in place an approved AppArmor profile to be used by containers that will manipulate the
on-host AppArmor profiles. This allows an init container in Pods to put customized AppArmor
profile in place and load them.

  - Project Scope: Drydock
  - Solution *Configurable*: A bootaction will put in place the profile-manager AppArmor profile and
    load it on each boot.
  - Audit: *Pending*: The availability of this profile will be verified by a Sonobuoy plugin.

.. IMPORTANT::

  All other AppArmor profiles must be delivered and loaded by an init container in the Pod
  that requires them. The Pod must also be decorated with the appropriate annotation to specify
  the custom profile.

System Monitoring
^^^^^^^^^^^^^^^^^

Run `rsyslogd` to log events.

  - Project Scope: Drydock
  - Solution *Remediated*: MAAS installs rsyslog by default.
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin.

Run a monitor for logging kernel audit events such as auditd.

  - Project Scope: Non-Airship
  - Solution *Remediated*: The `Sysdig Falco <https://sysdig.com/opensource/falco/>`_ will be used
    and
  - Audit: *Pending*: This will be verified on an ongoing basis via a Sonobuoy plugin.

Watch the watchers. Ensure that monitoring services are up and responsive.

  - Project Scope: Non-Airship
  - Solution *Remediated*: Nagios will monitor host services and Kubernetes resources
  - Audit: *Validation*: Internal corporate systems track Nagios heartbeats to ensure Nagios is responsive

Blacklisted Services
^^^^^^^^^^^^^^^^^^^^

The below services are deprecated and should not be enabled or installed on hosts.

================ ====================
  Service          Ubuntu Package
================ ====================
 telnet           telnetd
 inet telnet      inetutils-telnetd
 SSL telnet       telnetd-ssl
 NIS              nis
 NTP date         ntpdate
================ ====================

  - Project Scope: Drydock
  - Solution *Configurable*: A boot action will be used to enforce this on first boot.
  - Audit: *Pending*: This will be verified on an ongoing basis via Sonobuoy plugin.

Required System Services
^^^^^^^^^^^^^^^^^^^^^^^^

``cron`` and ``ntpd`` **must** be installed and enabled on all hosts. Only administrative
accounts should have access to cron. ``ntpd -q`` should show time synchronization is active.

  - Project Scope: Drydock
  - Solution *Remediated*: A MAAS deployed node runs cron and configured ntpd by default.
  - Audit: *Pending*: This will be verified on an ongoing basis via Sonobuoy plugin.

System Service Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If ``sshd`` is enabled, ensure it is securely configured:

  - **Must** only support protocol version 2 (``Protocol 2``)
  - **Must** disallow root SSH logins (``PermitRootLogin no``)
  - **Must** disallow empty passwords (``PermitEmptyPasswords no``)
  - **Should** set a idle timeout interval (``ClientAliveInterval 600`` and ``ClientAliveCountMax 0``)

  - Project Scope: Drydock
  - Solution *Configurable*: A boot action will install an explicit configuration file
  - Audit: *Pending*: This will be verified on an ongoing basis via Sonobuoy plugin.

Network Security
^^^^^^^^^^^^^^^^

.. IMPORTANT::

  Calico network policies will be used to secure host-level network access. Nothing will
  be orchestrated outside of Calico to enforce host-level network policy.

Secure the transport of traffic between nodes and MAAS/Drydock during node deployment.

  - Project Scope: Drydock, MAAS
  - Solution *Pending*: The Drydock and MAAS charts will be updated to include an Ingress
    port utilizing TLS 1.2 and a publicly signed certificate. Also the service will enable
    TLS on the pod IP.
  - Audit: *Testing*: The testing pipeline will validate the deployment is using TLS to
    access the Drydock and MAAS APIs.

.. DANGER::

  Some traffic, such as iPXE, DHCP, TFTP, will utilize node ports and is not encrypted. This
  is not configurable. However, this traffic traverses the private PXE network.

Secure Accounts
^^^^^^^^^^^^^^^

Enforce a minimum password length of 8 characters

  - Project Scope: Drydock
  - Solution *Configurable*: A boot action will update ``/etc/pam.d/common-password`` to specify ``minlen=8`` for ``pam_unix.so``.
  - Audit: *Pending*: This will be verified on an ongoing basis via Sonobuoy plugin.

Configuration Guidance
----------------------

Filesystem Configuration
^^^^^^^^^^^^^^^^^^^^^^^^

The filesystem partitioning strategy should be sure to protect the ability for the host to
log critical information, both for security and reliability. The log data should not risk
filling up the root filesystem (``/``) and non-critical log data should not risk crowding out
critical log data. If you are shipping log data to a remote store, the latter concern is
less critical. Because Airship nodes are built to **ONLY** run Kubernetes, isolating filesystems
such as ``/home`` is not as critical since there is no direct user access and applications
are running in a containerized environment.

Temporary Mitigation Status
---------------------------


References
----------

  * `OpenSCAP for Ubuntu 16.04 <https://static.open-scap.org/ssg-guides/ssg-ubuntu1604-guide-common.html>`_
  * `Ubuntu 16.04 Server Guide <https://help.ubuntu.com/16.04/serverguide/security.html>`_
  * `Canonical MAAS 2.3 TLS <https://docs.maas.io/2.3/en/installconfig-network-ssl>`_
  * `Canonical MAAS 2.4 TLS <https://docs.maas.io/2.4/en/installconfig-network-ssl>`_
