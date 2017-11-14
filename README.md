# UCP Integration

UCP, or Undercloud Platform, is a broad integration of several components
enabling an automated, resilient Kubernetes-based infrastructure for hosting
Helm-deployed containerized workloads

Find documentation for Undercloud Platform Integration on
[readthedocs](http://ucpintegration.readthedocs.org).

## Components

### Shipyard

Platform orchestrator for initial deployment, platform updates, and server
redeployments

### Promenade

The bootstrapper for the Kubernetes control plane - both on an initial genesis node
to get a working Kubernetes cluster and for adding additional nodes to the existing
Kubernetes cluster.

### Armada

Provisioner for Helm charts. Provides the capability to override chart values.yaml
items.

### Drydock

The orchestrator for physical asset provisioning (e.g. server deployment).

### Deckhand

YAML design data manager.
