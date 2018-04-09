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

.. _deployment-grouping-baremetal:

Deployment Grouping for Baremetal Nodes
=======================================
One of the primary functionalities of the Undercloud Platform is the deployment
of baremetal nodes as part of site deployment and upgrade. This blueprint aims
to define how deployment strategies can be applied to the workflow during these
actions.

Overview
--------
When Shipyard is invoked for a deploy_site or update_site action, there are
three primary stages:

1. Preparation and Validation
2. Baremetal and Network Deployment
3. Software Deployment

During the Baremetal and Network Deployment stage, the deploy_site or
update_site workflow (and perhaps other workflows in the future) invokes
Drydock to verify the site, prepare the site, prepare the nodes, and deploy the
nodes. Each of these steps is described in the `Drydock Orchestrator Readme`_

.. _Drydock Orchestrator Readme: https://github.com/att-comdev/drydock/tree/master/drydock_provisioner/orchestrator

The prepare nodes and deploy nodes steps each involve intensive and potentially
time consuming operations on the target nodes, orchestrated by Drydock and
MAAS. These steps need to be approached and managed such that grouping,
ordering, and criticality of success of nodes can be managed in support of
fault tolerant site deployments and updates.

For the purposes of this document `phase of deployment` refer to the prepare
nodes and deploy nodes steps of the Baremetal and Network deployment.

Some factors that advise this solution:

1. Limits to the amount of parallelization that can occur due to a centralized
   MAAS system.
2. Faults in the hardware, preventing operational nodes.
3. Miswiring or configuration of network hardware.
4. Incorrect site design causing a mismatch against the hardware.
5. Criticality of particular nodes to the realization of the site design.
6. Desired configurability within the framework of the UCP declarative site
   design.
7. Improved visibility into the current state of node deployment.
8. A desire to begin the deployment of nodes before the finish of the
   preparation of nodes -- i.e. start deploying nodes as soon as they are ready
   to be deployed. Note: This design will not achieve new forms of
   task parallelization within Drydock; this is recognized as a desired
   functionality.

Solution
--------
Updates supporting this solution will require changes to Shipyard for changed
workflows and Drydock for the desired node targeting, and for retrieval of
diagnostic and result information.

Deployment Strategy Document (Shipyard)
---------------------------------------
To accommodate the needed changes, this design introduces a new
DeploymentStrategy document into the site design to be read and utilized
by the workflows for update_site and deploy_site.

Groups
~~~~~~
Groups are named sets of nodes that will be deployed together. The fields of a
group are:

name
  Required. The identifying name of the group.

critical
  Required. Indicates if this group is required to continue to additional
  phases of deployment.

depends_on
  Required, may be empty list. Group names that must be successful before this
  group can be processed.

selectors
  Required, may be empty list. A list of identifying information to indicate
  the nodes that are members of this group.

success_criteria
  Optional. Criteria that must evaluate to be true before a group is considered
  successfully complete with a phase of deployment.

Criticality
'''''''''''
- Field: critical
- Valid values: true | false

Each group is required to indicate true or false for the `critical` field.
This drives the behavior after the deployment of baremetal nodes.  If any
groups that are marked as `critical: true` fail to meet that group's success
criteria, the workflow should halt after the deployment of baremetal nodes. A
group that cannot be processed due to a parent dependency failing will be
considered failed, regardless of the success criteria.

Dependencies
''''''''''''
- Field: depends_on
- Valid values: [] or a list of group names

Each group specifies a list of depends_on groups, or an empty list. All
identified groups must complete successfully for the phase of deployment before
the current group is allowed to be processed by the current phase.

- A failure (based on success criteria) of a group prevents any groups
  dependent upon the failed group from being attempted.
- Circular dependencies will be rejected as invalid during document validation.
- There is no guarantee of ordering among groups that have their dependencies
  met. Any group that is ready for deployment based on declared dependencies
  will execute. Execution of groups is serialized - two groups will not deploy
  at the same time.

Selectors
'''''''''
- Field: selectors
- Valid values: [] or a list of selectors

The list of selectors indicate the nodes that will be included in a group.
Each selector has four available filtering values: node_names, node_tags,
node_labels, and rack_names. Each selector is an intersection of this
critera, while the list of selectors is a union of the individual selectors.

- Omitting a criterion from a selector, or using empty list means that criterion
  is ignored.
- Having a completely empty list of selectors, or a selector that has no
  criteria specified indicates ALL nodes.
- A collection of selectors that results in no nodes being identified will be
  processed as if 100% of nodes successfully deployed (avoiding division by
  zero), but would fail the minimum or maximum nodes criteria (still counts as
  0 nodes)
- There is no validation against the same node being in multiple groups,
  however the workflow will not resubmit nodes that have already completed or
  failed in this deployment to Drydock twice, since it keeps track of each node
  uniquely. The success or failure of those nodes excluded from submission to
  Drydock will still be used for the success criteria calculation.

E.g.::

  selectors:
    - node_names:
        - node01
        - node02
      rack_names:
        - rack01
      node_tags:
        - control
    - node_names:
        - node04
      node_labels:
        - ucp_control_plane: enabled

Will indicate (not really SQL, just for illustration)::

    SELECT nodes
    WHERE node_name in ('node01', 'node02')
          AND rack_name in ('rack01')
          AND node_tags in ('control')
    UNION
    SELECT nodes
    WHERE node_name in ('node04')
          AND node_label in ('ucp_control_plane: enabled')

Success Criteria
''''''''''''''''
- Field: success_criteria
- Valid values: for possible values, see below

Each group optionally contains success criteria which is used to indicate if
the deployment of that group is successful. The values that may be specified:

percent_successful_nodes
  The calculated success rate of nodes completing the deployment phase.

  E.g.: 75 would mean that 3 of 4 nodes must complete the phase successfully.

  This is useful for groups that have larger numbers of nodes, and do not
  have critical minimums or are not sensitive to an arbitrary number of nodes
  not working.

minimum_successful_nodes
  An integer indicating how many nodes must complete the phase to be considered
  successful.

maximum_failed_nodes
  An integer indicating a number of nodes that are allowed to have failed the
  deployment phase and still consider that group successful.

When no criteria are specified, it means that no checks are done - processing
continues as if nothing is wrong.

When more than one criterion is specified, each is evaluated separately - if
any fail, the group is considered failed.


Example Deployment Strategy Document
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This example shows a deployment strategy with 5 groups: control-nodes,
compute-nodes-1, compute-nodes-2, monitoring-nodes, and ntp-node.

::

  ---
  schema: shipyard/DeploymentStrategy/v1
  metadata:
    schema: metadata/Document/v1
    name: deployment-strategy
    layeringDefinition:
        abstract: false
        layer: global
    storagePolicy: cleartext
  data:
    groups:
      - name: control-nodes
        critical: true
        depends_on:
          - ntp-node
        selectors:
          - node_names: []
            node_labels: []
            node_tags:
              - control
            rack_names:
              - rack03
        success_criteria:
          percent_successful_nodes: 90
          minimum_successful_nodes: 3
          maximum_failed_nodes: 1
      - name: compute-nodes-1
        critical: false
        depends_on:
          - control-nodes
        selectors:
          - node_names: []
            node_labels: []
            rack_names:
              - rack01
            node_tags:
              - compute
        success_criteria:
          percent_successful_nodes: 50
      - name: compute-nodes-2
        critical: false
        depends_on:
          - control-nodes
        selectors:
          - node_names: []
            node_labels: []
            rack_names:
              - rack02
            node_tags:
              - compute
        success_criteria:
          percent_successful_nodes: 50
      - name: monitoring-nodes
        critical: false
        depends_on: []
        selectors:
          - node_names: []
            node_labels: []
            node_tags:
              - monitoring
            rack_names:
              - rack03
              - rack02
              - rack01
      - name: ntp-node
        critical: true
        depends_on: []
        selectors:
          - node_names:
              - ntp01
            node_labels: []
            node_tags: []
            rack_names: []
        success_criteria:
          minimum_successful_nodes: 1

The ordering of groups, as defined by the dependencies (``depends-on``
fields)::

   __________     __________________
  | ntp-node |   | monitoring-nodes |
   ----------     ------------------
       |
   ____V__________
  | control-nodes |
   ---------------
       |_________________________
           |                     |
     ______V__________     ______V__________
    | compute-nodes-1 |   | compute-nodes-2 |
     -----------------     -----------------

Given this, the order of execution could be:

- ntp-node > monitoring-nodes > control-nodes > compute-nodes-1 > compute-nodes-2
- ntp-node > control-nodes > compute-nodes-2 > compute-nodes-1 > monitoring-nodes
- monitoring-nodes > ntp-node > control-nodes > compute-nodes-1 > compute-nodes-2
- and many more ... the only guarantee is that ntp-node will run some time
  before control-nodes, which will run sometime before both of the
  compute-nodes. Monitoring-nodes can run at any time.

Also of note are the various combinations of selectors and the varied use of
success criteria.

Deployment Configuration Document (Shipyard)
--------------------------------------------
The existing deployment-configuration document that is used by the workflows
will also be modified to use the existing deployment_strategy field to provide
the name of the deployment-straegy document that will be used.

The default value for the name of the DeploymentStrategy document will be
``deployment-strategy``.

Drydock Changes
---------------

API and CLI
~~~~~~~~~~~
- A new API needs to be provided that accepts a node filter (i.e. selector,
  above) and returns a list of node names that result from analysis of the
  design. Input to this API will also need to include a design reference.

- Drydock needs to provide a "tree" output of tasks rooted at the requested
  parent task. This will provide the needed success/failure status for nodes
  that have been prepared/deployed.

Documentation
~~~~~~~~~~~~~
Drydock documentation will be updated to match the introduction of new APIs


Shipyard Changes
----------------

API and CLI
~~~~~~~~~~~
- The commit configdocs api will need to be enhanced to look up the
  DeploymentStrategy by using the DeploymentConfiguration.
- The DeploymentStrategy document will need to be validated to ensure there are
  no circular dependencies in the groups' declared dependencies (perhaps
  NetworkX_).
- A new API endpoint (and matching CLI) is desired to retrieve the status of
  nodes as known to Drydock/MAAS and their MAAS status. The existing node list
  API in Drydock provides a JSON output that can be utilized for this purpose.

Workflow
~~~~~~~~
The deploy_site and update_site workflows will be modified to utilize the
DeploymentStrategy.

- The deployment configuration step will be enhanced to also read the
  deployment strategy and pass the information on a new xcom for use by the
  baremetal nodes step (see below)
- The prepare nodes and deploy nodes steps will be combined to perform both as
  part of the resolution of an overall ``baremetal nodes`` step.
  The baremetal nodes step will introduce functionality that reads in the
  deployment strategy (from the prior xcom), and can orchestrate the calls to
  Drydock to enact the grouping, ordering and and success evaluation.
  Note that Drydock will serialize tasks; there is no parallelization of
  prepare/deploy at this time.

Needed Functionality
''''''''''''''''''''

- function to formulate the ordered groups based on dependencies (perhaps
  NetworkX_)
- function to evaluate success/failure against the success criteria for a group
  based on the result list of succeeded or failed nodes.
- function to mark groups as success or failure (including failed due to
  dependency failure), as well as keep track of the (if any) successful and
  failed nodes.
- function to get a group that is ready to execute, or 'Done' when all groups
  are either complete or failed.
- function to formulate the node filter for Drydock based on a group's
  selectors
- function to orchestrate processing groups, moving to the next group (or being
  done) when a prior group completes or fails.
- function to summarize the success/failed nodes for a group (primarily for
  reporting to the logs at this time).

Process
'''''''
The baremetal nodes step (preparation and deployment of nodes) will proceed as
follows:

1. Each group's selector will be sent to Drydock to determine the list of
   nodes that are a part of that group.

   - An overall status will be kept for each unique node (not started |
     prepared | success | failure).
   - When sending a task to Drydock for processing, the nodes associated with
     that group will be sent as a simple `node_name` node filter. This will
     allow for this list to exclude nodes that have a status that is not
     congruent for the task being performed.

     - prepare nodes valid status: not started
     - deploy nodes valid status: prepared

2. In a processing loop, groups that are ready to be processed based on their
   dependencies (and the success criteria of groups they are dependent upon)
   will be selected for processing until there are no more groups that can be
   processed. The processing will consist of preparing and then deploying the
   group.

   - The selected group will be prepared and then deployed before selecting
     another group for processing.
   - Any nodes that failed as part of that group will be excluded from
     subsequent deployment or preparation of that node for this deployment.

     - Excluding nodes that are already processed addresses groups that have
       overlapping lists of nodes due to the group's selectors, and prevents
       sending them to Drydock for re-processing.
     - Evaluation of the success criteria will use the full set of nodes
       identified by the selector. This means that if a node was previously
       successfully deployed, that same node will count as "successful" when
       evaluating the success criteria.

   - The success criteria will be evaluated after the group's prepare step and
     the deploy step. A failure to meet the success criteria in a prepare step
     will cause the deploy step for that group to be skipped (and marked as
     failed).
   - Any nodes that fail during the prepare step, will not be used in the
     corresponding deploy step.
   - Upon completion (success, partial success, or failure) of a prepare step,
     the nodes that were sent for preparation will be marked in the unique list
     of nodes (above) with their appropriate status: prepared or failure
   - Upon completion of a group's deployment step, the nodes status will be
     updated to their current status: success or failure.

4. Before the end of the baremetal nodes step, following all eligible group
   processing, a report will be logged to indicate the success/failure of
   groups and the status of the individual nodes. Note that it is possible for
   individual nodes to be left in `not started` state if they were only part of
   groups that were never allowed to process due to dependencies and success
   criteria.

5. At the end of the baremetal nodes step, if any nodes that have failed
   due to timeout, dependency failure, or success criteria failure and are
   marked as critical will trigger an Airflow Exception, resulting in a failed
   deployment.

Notes:

- The timeout values specified for the prepare nodes and deploy nodes steps
  will be used to put bounds on the individual calls to Drydock. A failure
  based on these values will be treated as a failure for the group; we need to
  be vigilant on if this will lead to indeterminate states for nodes that mess
  with further processing. (e.g. Timed out, but the requested work still
  continued to completion)

Example Processing
''''''''''''''''''
Using the defined deployment strategy in the above example, the following is
an example of how it may process::

  Start
  |
  | prepare ntp-node           <SUCCESS>
  | deploy ntp-node            <SUCCESS>
  V
  | prepare control-nodes      <SUCCESS>
  | deploy control-nodes       <SUCCESS>
  V
  | prepare monitoring-nodes   <SUCCESS>
  | deploy monitoring-nodes    <SUCCESS>
  V
  | prepare compute-nodes-2    <SUCCESS>
  | deploy compute-nodes-2     <SUCCESS>
  V
  | prepare compute-nodes-1    <SUCCESS>
  | deploy compute-nodes-1     <SUCCESS>
  |
  Finish (success)

If there were a failure in preparing the ntp-node, the following would be the
result::

  Start
  |
  | prepare ntp-node           <FAILED>
  | deploy ntp-node            <FAILED, due to prepare failure>
  V
  | prepare control-nodes      <FAILED, due to dependency>
  | deploy control-nodes       <FAILED, due to dependency>
  V
  | prepare monitoring-nodes   <SUCCESS>
  | deploy monitoring-nodes    <SUCCESS>
  V
  | prepare compute-nodes-2    <FAILED, due to dependency>
  | deploy compute-nodes-2     <FAILED, due to dependency>
  V
  | prepare compute-nodes-1    <FAILED, due to dependency>
  | deploy compute-nodes-1     <FAILED, due to dependency>
  |
  Finish (failed due to critical group failed)

If a failure occurred during the deploy of compute-nodes-2, the following would
result::

  Start
  |
  | prepare ntp-node           <SUCCESS>
  | deploy ntp-node            <SUCCESS>
  V
  | prepare control-nodes      <SUCCESS>
  | deploy control-nodes       <SUCCESS>
  V
  | prepare monitoring-nodes   <SUCCESS>
  | deploy monitoring-nodes    <SUCCESS>
  V
  | prepare compute-nodes-2    <SUCCESS>
  | deploy compute-nodes-2     <FAILED>
  V
  | prepare compute-nodes-1    <SUCCESS>
  | deploy compute-nodes-1     <SUCCESS>
  |
  Finish (success with some nodes/groups failed)

Schemas
~~~~~~~
A new schema will need to be provided by Shipyard to validate the
DeploymentStrategy document.

Documentation
~~~~~~~~~~~~~
The Shipyard action documentation will need to include details defining the
DeploymentStrategy document (mostly as defined here), as well as the update to
the DeploymentConfiguration document to contain the name of the
DeploymentStrategy document.


.. _NetworkX: https://networkx.github.io/documentation/networkx-1.9/reference/generated/networkx.algorithms.dag.topological_sort.html
