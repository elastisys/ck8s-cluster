#!/bin/bash
# Script used by pipeline to cleanup volumes in safespring.
# Can be used manually if the cluster is still intact and
# kube_config to service cluster is in the current working directory.
set -e

export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml

kubectl delete ns elastic-system harbor monitoring fluentd influxdb-prometheus
kubectl delete pv --all --wait

volumes_left="$(kubectl get pv -o json | jq '.items[] | {pv_name: .metadata.name, pvc_namespace: .spec.claimRef.namespace, pvc_name: .spec.claimRef.name}')"
if [[ "$volumes_left" != "" ]]
then
    echo "Warning: There seems to be volumes left in the cluster, this will result in volumes on safespring that needs to be cleaned up manually."
    echo "Volumes left:"
    echo "$volumes_left"
    exit 1
fi
echo "Cleanup of volumes completed!"