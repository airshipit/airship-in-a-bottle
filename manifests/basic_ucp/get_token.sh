#!/bin/bash
TOKEN=$(docker run --rm --net=host -e 'OS_AUTH_URL=http://keystone-api.ucp.svc.cluster.local:80/v3' -e 'OS_PASSWORD=password' -e 'OS_PROJECT_DOMAIN_NAME=default' -e 'OS_PROJECT_NAME=service' -e 'OS_REGION_NAME=RegionOne' -e 'OS_USERNAME=drydock' -e 'OS_USER_DOMAIN_NAME=default' -e 'OS_IDENTITY_API_VERSION=3' kolla/ubuntu-source-keystone:3.0.3 openstack token issue -f shell | grep ^id | cut -d'=' -f2 | tr -d '"')

echo $TOKEN
