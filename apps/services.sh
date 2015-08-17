#!/bin/bash

OSCONFIG=/opt/bin/openshift.local.config/master
DOMAIN=befaircloud.me


oc create -f serviceaccounts.yaml

# Registry
# https://docs.openshift.org/latest/admin_guide/install/docker_registry.html
oadm registry \
--config=${OSCONFIG}/admin.kubeconfig \
--credentials=${OSCONFIG}/openshift-registry.kubeconfig
#--mount-host=/var/lib/openshift/docker-registry

#TODO

# reg3
#oc create -f /opt/bin/registry.yaml
#oc get scc privileged -o yaml
#mkdir -p /var/lib/openshift/docker-registry
#oadm registry --service-account=registry \
#  --config=/etc/openshift/master/admin.kubeconfig \
#  --credentials=/etc/openshift/master/openshift-registry.kubeconfig \
#  --mount-host=/mnt/registry \
#  --images='openshift3/ose-${component}:v3.0.0.0' \
#  --selector="region=infra"

# Networking/Router
# https://docs.openshift.org/latest/admin_guide/install/deploy_router.html
# https://docs.openshift.org/latest/architecture/core_concepts/routes.html
# http://blog.kubernetes.io/2015/07/strong-simple-ssl-for-kubernetes.html
oc create -f routing.yaml
echo
echo 'at the end, append the following line: '
echo '- system:serviceaccount:default:router'
echo
oc edit scc privileged
oadm router ex-router \
--replicas=1 \
--credentials="$KUBECONFIG" \
--service-account=router

#oadm ca create-server-cert \
#  --signer-cert=${OSCONFIG}/ca.crt \
#  --signer-key=${OSCONFIG}/ca.key \
#  --signer-serial=${OSCONFIG}/ca.serial.txt \
#  --hostnames='*.${DOMAIN}' \
#  --cert=routerdef.crt --key=routerdef.key
#cat routerdef.crt routerdef.key ${OSCONFIG}/ca.crt > routerdef.router.pem
#oadm router \
#  --default-cert=routerdef.router.pem \
#  --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
#  --selector='region=infra' \
#  --credentials='/etc/openshift/master/openshift-router.kubeconfig'


# Networking/DNS
# https://docs.openshift.org/latest/architecture/additional_concepts/networking.html
# https://docs.openshift.org/latest/architecture/additional_concepts/sdn.html
# http://kubernetes.io/v1.0/docs/admin/dns.html


# Monitoring
# https://docs.openshift.org/latest/admin_guide/cluster_metrics.html
oadm policy add-cluster-role-to-user \
  cluster-reader \
  system:serviceaccount:default:heapster
oc create -f monitoring.yaml

# Logging
# https://docs.openshift.org/latest/admin_guide/aggregate_logging.html
# http://kubernetes.io/v1.0/docs/user-guide/logging.html
# http://kubernetes.io/v1.0/docs/getting-started-guides/logging-elasticsearch.html


# Persistent Storage (NFS)
# http://kubernetes.io/v1.0/docs/user-guide/volumes.html
# http://kubernetes.io/v1.0/docs/user-guide/persistent-volumes.html
# https://docs.openshift.org/latest/admin_guide/persistent_storage_nfs.html
# https://github.com/openshift/origin/tree/master/examples/wordpress


# the directories in this example can grow unbounded
# use disk partitions of specific sizes to enforce storage quotas
#mkdir /home/data/pv0001 
#mkdir /home/data/pv0002

# data written to NFS by a pod gets squashed by NFS and is owned by 'nfsnobody'
# we'll make our export directories owned by the same user
#chown -R /home/data nfsnobody:nfsnobody

# security needs to be permissive currently, but the export will soon be restricted 
# to the same UID/GID that wrote the data
#chmod -R 777 /home/data/

# Add to /etc/exports
#/home/data/pv0001 *(rw,sync,no_root_squash)
#/home/data/pv0002 *(rw,sync,no_root_squash)

# Enable the new exports without bouncing the NFS service
#exportfs -a

#echo 'Change "runAsUser" from MustRunAsRange to RunAsAny'
#oc edit scc restricted

# Create the persistent volumes for NFS.
#$ oc create -f examples/wordpress/pv-nfs-1.yaml
#$ oc create -f examples/wordpress/pv-nfs-2.yaml

# Create claims for storage.
# The claims in this example carefully match the volumes created above.
#$ oc create -f examples/wordpress/pvc-wp.yaml
#$ oc create -f examples/wordpress/pvc-mysql.yaml

# Launch the MySQL pod.
#oc create -f examples/wordpress/pod-mysql.yaml

# Security Context Constraint
# https://docs.openshift.org/latest/admin_guide/manage_scc.html
echo
echo 'allowPrivilegedContainer: true'
echo
echo 'runAsUser:'
echo '  type: RunAsAny'
echo
oc edit scc restricted
