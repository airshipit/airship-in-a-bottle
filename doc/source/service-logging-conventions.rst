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

.. _service-logging-conventions:

Service Logging Conventions
===========================
Airship services must provide logging, should conform to a standard logging
format, and may utilize shared code to do so.

Standard Logging Format
-----------------------
The following is the intended format to be used when logging from Airship
services. When logging from those parts that are no services, a close
reasonable approximation is desired.

::

  Timestamp Level RequestID ExternalContextID ModuleName(Line) Function - Message

Where:

-  Timestamp is like ``2006-02-08 22:20:02,165``, or the standard ouptut from
   ``%(asctime)s``
-  Level is 'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL', padded to 8
   characters, left aligned.
-  RequestID is the UUID assigned to the request in canonical 8-4-4-4-12 format.
-  ExternalContextID is the UUID assigned from the external source (or generated
   for the same purpose), in 8-4-4-4-12 format.
-  ModuleName is the name of the module or class from which the logging
   originates.
-  Line is the line number of the logging statement
-  Function is the name of the function or method from which the logging
   originates
-  Message is the text of the message to be logged.

Example Python Logging Format
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

  %(asctime)s %(levelname)-8s %(req_id)s %(external_ctx)s %(user)s %(module)s(%(lineno)d) %(funcName)s - %(message)s'

See `Python Logging`_ for explanation of format.

Loggers in Code
---------------
Components should prefer loggers that are at the module or class level,
allowing for finer grained logging control than a global logger.


.. _Python Logging: https://docs.python.org/3/library/logging.html