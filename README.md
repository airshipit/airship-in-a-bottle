# Airship in a Bottle

Airship is a new name for the project, formerly known as UCP.  References to
'UCP' or 'Undercloud Platform' will be corrected in time.

Airship is a broad integration of several components
enabling an automated, resilient Kubernetes-based infrastructure for hosting
Helm-deployed containerized workloads.

To get started, run the following in a fresh Ubuntu 16.04 VM
(minimum 4vCPU/20GB RAM/32GB disk). This will deploy Airship and Openstack Helm
(OSH):
```
sudo -i
mkdir -p /root/deploy && cd "$_"
git clone https://git.openstack.org/openstack/airship-in-a-bottle
cd /root/deploy/airship-in-a-bottle/manifests/dev_single_node
./airship-in-a-bottle.sh
```

Or, alternatively, if you have Vagrant installed, just run the following
(only libvirt/kvm hypervisor is tested, but vagrant box supports VMware
Desktop/Workstation/Fusion, Parallels, and Hyper-V):
```
curl -O https://git.airshipit.org/cgit/airship-in-a-bottle/plain/Vagrantfile
vagrant up
```

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
