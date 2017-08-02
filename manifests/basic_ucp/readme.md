# Artifacts to deploy a basic UCP control plane

The scripts and artifacts in this directory can be used to deploy
a basic UCP control plane on a single node.

1. Generate Promenade configuration and certificates
2. Run Promenade genesis process to bootstrap Kubernetes
3. Deploy Ceph using Armada
4. Deploy UCP backend services (MariaDB, Postgres) using Armada
5. Deploy Drydock and MaaS using Armada

## Setup environment for your environment

This deployment process utilizes several environment variables to
customize the deployment to your environment. The set-env.sh file has
an example environment known to work.

* CEPH\_CLUSTER\_NET

    The CIDR of the network(s) that Ceph will utilize for storage replication and
    other intra-cluster communication. Can be a comma-separated list of CIDRs.

* CEPH\_PUBLIC\_NET

    The CIDR of the network(s) that Ceph will utilize for accepting requests
    for storage provisioning. Can be a comma-separated list of CIDRs.

* CEPH\_OSD\_DIR

    The directory Ceph will use for OSD storage

* GENESIS\_NODE\_IP

    The IP address of the genesis node or VM.

* MASTER\_NODE\_IP

    The IP address of the second node to be added to the cluster. Scripting does not yet
    support deployment of this node, but it is *REQUIRED* to be included in the bootstrap
    configuration

* DRYDOCK\_NODE\_IP

    The IP address of the node that will host the Drydock container. Defaults to the genesis
    node which is normally correct.

* MAAS\_NODE\_IP

    The IP address of the node that will hsot the MaaS container. Defaults to the genesis
    node which is normally correct.

* NODE\_NET\_IFACE

    The NIC interface on each node that Calico should use to access the underlay network. Defaults
    to 'eth0'

* PROXY\_ADDRESS

    If a HTTP/HTTPS proxy is needed for public access, specify the address here in URL format.

* PROXY\_ENABLED

    Whether to enable proxy use. Should be 'true' or 'false', defaults to 'false'.

* GENESIS\_NODE\_NAME

    The hostname of the genesis node. REQUIRED to be accurate. Defaults to 'node1'

* MASTER\_NODE\_NAME

    The hostname of the master (or second) node. REQUIRED to be accurate. Defaults to 'node2'

* \*\_CHART\_REPO

    The Git repository used for pulling charts. \* can be any of 'CEPH', 'DRYDOCK' or 'MAAS'

* \*\_CHART\_BRANCH

    The Git branch used for pulling charts. \* can be any of 'CEPH', 'DRYDOCK' or 'MAAS'

* \*\_IMAGE

    The Docker image file used for deployments and running commands. \* can be any of 'DRYDOCK',
    'ARMADA', 'PROMENADE'.

## Run the deployment

Once all of the above environmental variables are correct, run `deploy_ucp.sh` as root.
