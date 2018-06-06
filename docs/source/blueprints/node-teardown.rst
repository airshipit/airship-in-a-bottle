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

.. _node-teardown:

Undercloud Node Teardown
========================

When redeploying a physical host (server) using the Undercloud Platform(UCP),
it is necessary to trigger a sequence of steps to prevent undesired behaviors
when the server is redeployed. This blueprint intends to document the
interaction that must occur between UCP components to teardown a server.

Overview
--------
Shipyard is the entrypoint for UCP actions, including the need to redeploy a
server. The first part of redeploying a server is the graceful teardown of the
software running on the server; specifically Kubernetes and etcd are of
critical concern. It is the duty of Shipyard to orchestrate the teardown of the
server, followed by steps to deploy the desired new configuration. This design
covers only the first portion - node teardown

Shipyard node teardown Process
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#. (Existing) Shipyard receives request to redeploy_server, specifying a target
   server.
#. (Existing) Shipyard performs preflight, design reference lookup, and
   validation steps.
#. (New) Shipyard invokes Promenade to decommission a node.
#. (New) Shipyard invokes Drydock to destroy the node - setting a node
   filter to restrict to a single server.
#  (New) Shipyard invokes Promenade to remove the node from the Kubernetes
   cluster.

Assumption:
node_id is the hostname of the server, and is also the identifier that both
Drydock and Promenade use to identify the appropriate parts - hosts and k8s
nodes. This convention is set by the join script produced by promenade.

Drydock Destroy Node
--------------------
The API/interface for destroy node already exists. The implementation within
Drydock needs to be developed. This interface will need to accept both the
specified node_id and the design_id to retrieve from Deckhand.

Using the provided node_id (hardware node), and the design_id, Drydock will
reset the hardware to a re-provisionable state.

By default, all local storage should be wiped (per datacenter policy for
wiping before re-use).

An option to allow for only the OS disk to be wiped should be supported, such
that other local storage is left intact, and could be remounted without data
loss. e.g.: --preserve-local-storage

The target node should be shut down.

The target node should be removed from the provisioner (e.g. MaaS)

Responses
~~~~~~~~~
The responses from this functionality should follow the pattern set by prepare
nodes, and other Drydock functionality. The Drydock status responses used for
all async invocations will be utilized for this functionality.

Promenade Decommission Node
---------------------------
Performs steps that will result in the specified node being cleanly
disassociated from Kubernetes, and ready for the server to be destroyed.
Users of the decommission node API should be aware of the long timeout values
that may occur while awaiting promenade to complete the appropriate steps.
At this time, Promenade is a stateless service and doesn't use any database
storage. As such, requests to Promenade are synchronous.

.. code:: json

  POST /nodes/{node_id}/decommission

  {
    rel : "design",
    href: "deckhand+https://{{deckhand_url}}/revisions/{{revision_id}}/rendered-documents",
    type: "application/x-yaml"
  }

Such that the design reference body is the design indicated when the
redeploy_server action is invoked through Shipyard.

Query Parameters:

-  drain-node-timeout: A whole number timeout in seconds to be used for the
   drain node step (default: none). In the case of no value being provided,
   the drain node step will use its default.
-  drain-node-grace-period: A whole number in seconds indicating the
   grace-period that will be provided to the drain node step. (default: none).
   If no value is specified, the drain node step will use its default.
-  clear-labels-timeout: A whole number timeout in seconds to be used for the
   clear labels step. (default: none).  If no value is specified, clear labels
   will use its own default.
-  remove-etcd-timeout: A whole number timeout in seconds to be used for the
   remove etcd from nodes step. (default: none). If no value is specified,
   remove-etcd will use its own default.
-  etcd-ready-timeout: A whole number in seconds indicating how long the
   decommission node request should allow for etcd clusters to become stable
   (default: 600).

Process
~~~~~~~
Acting upon the node specified by the invocation and the design reference
details:

#. Drain the Kubernetes node.
#. Clear the Kubernetes labels on the node.
#. Remove etcd nodes from their clusters (if impacted).
   -  if the node being decommissioned contains etcd nodes, Promenade will
      attempt to gracefully have those nodes leave the etcd cluster.
#. Ensure that etcd cluster(s) are in a stable state.
   -  Polls for status every 30 seconds up to the etcd-ready-timeout, or the
      cluster meets the defined minimum functionality for the site.
   -  A new document: promenade/EtcdClusters/v1 that will specify details about
      the etcd clusters deployed in the site, including: identifiers,
      credentials, and thresholds for minimum functionality.
   -  This process should ignore the node being torn down from any calculation
      of health
#. Shutdown the kubelet.
   -  If this is not possible because the node is in a state of disarray such
      that it cannot schedule the daemonset to run, this step may fail, but
      should not hold up the process, as the Drydock dismantling of the node
      will shut the kubelet down.

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   Indicates that all steps are successful.

-  Failure: Code: 404, reason: NotFound

   Indicates that the target node is not discoverable by Promenade.

-  Failure: Code: 500, reason: DisassociateStepFailure

   The details section should detail the successes and failures further. Any
   4xx series errors from the individual steps would manifest as a 500 here.

Promenade Drain Node
--------------------
Drain the Kubernetes node for the target node. This will ensure that this node
is no longer the target of any pod scheduling, and evicts or deletes the
running pods. In the case of notes running DaemonSet manged pods, or pods
that would prevent a drain from occurring, Promenade may be required to provide
the `ignore-daemonsets` option or `force` option to attempt to drain the node
as fully as possible.

By default, the drain node will utilize a grace period for pods of 1800
seconds and a total timeout of 3600 seconds (1 hour). Clients of this
functionality should be prepared for a long timeout.

.. code:: json

  POST /nodes/{node_id}/drain

Query Paramters:

-  timeout: a whole number in seconds (default = 3600). This value is the total
   timeout for the kubectl drain command.
-  grace-period: a whole number in seconds (default = 1800). This value is the
   grace period used by kubectl drain. Grace period must be less than timeout.

.. note::

   This POST has no message body

Example command being used for drain (reference only)
`kubectl drain --force --timeout 3600s --grace-period 1800 --ignore-daemonsets --delete-local-data n1`
https://git.openstack.org/cgit/openstack/airship-promenade/tree/promenade/templates/roles/common/usr/local/bin/promenade-teardown

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   Indicates that the drain node has successfully concluded, and that no pods
   are currently running

-  Failure: Status response, code: 400, reason: BadRequest

   A request was made with parameters that cannot work - e.g. grace-period is
   set to a value larger than the timeout value.

-  Failure: Status response, code: 404, reason: NotFound

   The specified node is not discoverable by Promenade

-  Failure: Status response, code: 500, reason: DrainNodeError

   There was a processing exception raised while trying to drain a node. The
   details section should indicate the underlying cause if it can be
   determined.

Promenade Clear Labels
----------------------
Removes the labels that have been added to the target kubernetes node.

.. code:: json

  POST /nodes/{node_id}/clear-labels

Query Parameters:

-  timeout: A whole number in seconds allowed for the pods to settle/move
   following removal of labels. (Default = 1800)

.. note::

   This POST has no message body

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   All labels have been removed from the specified Kubernetes node.

-  Failure: Code: 404, reason: NotFound

   The specified node is not discoverable by Promenade

-  Failure: Code: 500, reason: ClearLabelsError

   There was a failure to clear labels that prevented completion. The details
   section should provide more information about the cause of this failure.

Promenade Remove etcd Node
~~~~~~~~~~~~~~~~~~~~~~~~~~
Checks if the node specified contains any etcd nodes. If so, this API will
trigger that etcd node to leave the associated etcd cluster.

POST /nodes/{node_id}/remove-etcd

  {
    rel : "design",
    href: "deckhand+https://{{deckhand_url}}/revisions/{{revision_id}}/rendered-documents",
    type: "application/x-yaml"
  }

Query Parameters:

-  timeout: A whole number in seconds allowed for the removal of etcd nodes
   from the targe node. (Default = 1800)

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   All etcd nodes have been removed from the specified node.

-  Failure: Code: 404, reason: NotFound

   The specified node is not discoverable by Promenade

-  Failure: Code: 500, reason: RemoveEtcdError

   There was a failure to remove etcd from the target node that prevented
   completion within the specified timeout, or that etcd prevented removal of
   the node because it would result in the cluster being broken. The details
   section should provide more information about the cause of this failure.


Promenade Check etcd
~~~~~~~~~~~~~~~~~~~~
Retrieves the current interpreted state of etcd.

GET /etcd-cluster-health-statuses?design_ref={the design ref}

Where the design_ref parameter is required for appropriate operation, and is in
the same format as used for the join-scripts API.

Query Parameters:

-  design_ref: (Required) the design reference to be used to discover etcd
   instances.

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   The status of each etcd in the site will be returned in the details section.
   Valid values for status are: Healthy, Unhealthy

https://github.com/att-comdev/ucp-integration/blob/master/docs/source/api-conventions.rst#status-responses

.. code:: json

  { "...": "... standard status response ...",
    "details": {
      "errorCount": {{n}},
      "messageList": [
        { "message": "Healthy",
          "error": false,
          "kind": "HealthMessage",
          "name": "{{the name of the etcd service}}"
        },
        { "message": "Unhealthy"
          "error": false,
          "kind": "HealthMessage",
          "name": "{{the name of the etcd service}}"
        },
        { "message": "Unable to access Etcd"
          "error": true,
          "kind": "HealthMessage",
          "name": "{{the name of the etcd service}}"
        }
      ]
    }
    ...
  }

-  Failure: Code: 400, reason: MissingDesignRef

   Returned if the design_ref parameter is not specified

-  Failure: Code: 404, reason: NotFound

   Returned if the specified etcd could not be located

-  Failure: Code: 500, reason: EtcdNotAccessible

   Returned if the specified etcd responded with an invalid health response
   (Not just simply unhealthy - that's a 200).


Promenade Shutdown Kubelet
--------------------------
Shuts down the kubelet on the specified node. This is accomplished by Promenade
setting the label `promenade-decomission: enabled` on the node, which will
trigger a newly-developed daemonset to run something like:
`systemctl disable kubelet && systemctl stop kubelet`.
This daemonset will effectively sit dormant until nodes have the appropriate
label added, and then perform the kubelet teardown.

.. code:: json

  POST /nodes/{node_id}/shutdown-kubelet

.. note::

   This POST has no message body

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   The kubelet has been successfully shutdown

-  Failure: Code: 404, reason: NotFound

   The specified node is not discoverable by Promenade

-  Failure: Code: 500, reason: ShutdownKubeletError

   The specified node's kubelet fails to shutdown. The details section of the
   status response should contain reasonable information about the source of
   this failure

Promenade Delete Node from Cluster
----------------------------------
Updates the Kubernetes cluster, removing the specified node. Promenade should
check that the node is drained/cordoned and has no labels other than
`promenade-decomission: enabled`. In either of these cases, the API should
respond with a 409 Conflict response.

.. code:: json

  POST /nodes/{node_id}/remove-from-cluster

.. note::

   This POST has no message body

Responses
~~~~~~~~~
All responses will be form of the UCP Status response.

-  Success: Code: 200, reason: Success

   The specified node has been removed from the Kubernetes cluster.

-  Failure: Code: 404, reason: NotFound

   The specified node is not discoverable by Promenade

-  Failure: Code: 409, reason: Conflict

   The specified node cannot be deleted due to checks that the node is
   drained/cordoned and has no labels (other than possibly
   `promenade-decomission: enabled`).

-  Failure: Code: 500, reason: DeleteNodeError

   The specified node cannot be removed from the cluster due to an error from
   Kubernetes. The details section of the status response should contain more
   information about the failure.


Shipyard Tag Releases
---------------------
Shipyard will need to mark Deckhand revisions with tags when there are
successful deploy_site or update_site actions to be able to determine the last
known good design. This is related to issue 16 for Shipyard, which utilizes the
same need.

.. note::

   Repeated from https://github.com/att-comdev/shipyard/issues/16

   When multiple configdocs commits have been done since the last deployment,
   there is no ready means to determine what's being done to the site. Shipyard
   should reject deploy site or update site requests that have had multiple
   commits since the last site true-up action. An option to override this guard
   should be allowed for the actions in the form of a parameter to the action.

   The configdocs API should provide a way to see what's been changed since the
   last site true-up, not just the last commit of configdocs. This might be
   accommodated by new deckhand tags like the 'commit' tag, but for
   'site true-up' or similar applied by the deploy and update site commands.

The design for issue 16 includes the bare-minimum marking of Deckhand
revisions. This design is as follows:

Scenario
~~~~~~~~
Multiple commits occur between site actions (deploy_site, update_site) - those
actions that attempt to bring a site into compliance with a site design.
When this occurs, the current system of being able to only see what has changed
between committed and the the buffer versions (configdocs diff) is insufficient
to be able to investigate what has changed since the last successful (or
unsuccessful) site action.
To accommodate this, Shipyard needs several enhancements.

Enhancements
~~~~~~~~~~~~

#. Deckhand revision tags for site actions

   Using the tagging facility provided by Deckhand, Shipyard will tag the end
   of site actions.
   Upon completing a site action successfully tag the revision being used with
   the tag site-action-success, and a body of dag_id:<dag_id>

   Upon completion of a site action unsuccessfully, tag the revision being used
   with the tag site-action-failure, and a body of dag_id:<dag_id>

   The completion tags should only be applied upon failure if the site action
   gets past document validation successfully (i.e. gets to the point where it
   can start making changes via the other UCP components)

   This could result in a single revision having both site-action-success and
   site-action-failure if a later re-invocation of a site action is successful.

#. Check for intermediate committed revisions

   Upon running a site action, before tagging the revision with the site action
   tag(s), the dag needs to check to see if there are committed revisions that
   do not have an associated site-action tag.  If there are any committed
   revisions since the last site action other than the current revision being
   used (between them), then the action should not be allowed to proceed (stop
   before triggering validations). For the calculation of intermediate
   committed revisions, assume revision 0 if there are no revisions with a
   site-action tag (null case)

   If the action is invoked with a parameter of
   allow-intermediate-commits=true, then this check should log that the
   intermediate committed revisions check is being skipped and not take any
   other action.

#. Support action parameter of allow-intermediate-commits=true|false

   In the CLI for create action, the --param option supports adding parameters
   to actions. The parameters passed should be relayed by the CLI to the API
   and ultimately to the invocation of the DAG.  The DAG as noted above will
   check for the presense of allow-intermediate-commits=true.  This needs to be
   tested to work.

#. Shipyard needs to support retrieving configdocs and rendered documents for
   the last successful site action, and last site action (successful or not
   successful)

   --successful-site-action
   --last-site-action
   These options would be mutually exclusive of --buffer or --committed

#. Shipyard diff (shipyard get configdocs)

   Needs to support an option to do the diff of the buffer vs. the last
   successful site action and the last site action (succesful or not
   successful).

   Currently there are no options to select which versions to diff (always
   buffer vs. committed)

   support:
   --base-version=committed | successful-site-action | last-site-action (Default = committed)
   --diff-version=buffer | committed | successful-site-action | last-site-action (Default = buffer)

   Equivalent query parameters need to be implemented in the API.

Because the implementation of this design will result in the tagging of
successful site-actions, Shipyard will be able to determine the correct
revision to use while attempting to teardown a node.

If the request to teardown a node indicates a revision that doesn't exist, the
command to do so (e.g. redeploy_server) should not continue, but rather fail
due to a missing precondition.

The invocation of the Promenade and Drydock steps in this design will utilize
the appropriate tag based on the request (default is successful-site-action) to
determine the revision of the Deckhand documents used as the design-ref.

Shipyard redeploy_server Action
-------------------------------
The redeploy_server action currently accepts a target node. Additional
supported parameters are needed:

#. preserve-local-storage=true which will instruct Drydock to only wipe the
   OS drive, and any other local storage will not be wiped. This would allow
   for the drives to be remounted to the server upon re-provisioning. The
   default behavior is that local storage is not preserved.

#. target-revision=committed | successful-site-action | last-site-action
   This will indicate which revision of the design will be used as the
   reference for what should be re-provisioned after the teardown.
   The default is successful-site-action, which is the closest representation
   to the last-known-good state.

These should be accepted as parameters to the action API/CLI and modify the
behavior of the redeploy_server DAG.