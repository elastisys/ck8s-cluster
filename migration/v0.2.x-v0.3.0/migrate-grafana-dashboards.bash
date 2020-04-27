#!/bin/bash
# This scripts migrates prometheus and grafana.
# Obs! Will cause temporary downtime to these services.
set -e
: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
here="$(dirname "$(readlink -f "$BASH_SOURCE")")"
root_path="${here}/../.."

echo "applying prometheus operator version 8.13.2"
${root_path}/bin/ck8s ops helmfile sc -e service_cluster -l app=prometheus-operator destroy
sleep 10
${root_path}/bin/ck8s ops helmfile sc -e service_cluster -l app=wc-scraper apply
${root_path}/bin/ck8s ops helmfile sc -e service_cluster -l app=prometheus-operator apply
${root_path}/bin/ck8s ops helmfile wc -e workload_cluster -l app=prometheus-operator destroy
sleep 10
${root_path}/bin/ck8s ops helmfile wc -e workload_cluster -l app=prometheus-operator apply

# Editing kube-proxy to fix prometheus endpoint.
echo "fixing kube-proxy endpoint"
${root_path}/bin/ck8s ops kubectl wc -n kube-system get configmap/kube-proxy -o yaml | sed "s/127.0.0.1/0.0.0.0/" | ${root_path}/bin/ck8s ops kubectl wc replace -f -
${root_path}/bin/ck8s ops kubectl sc -n kube-system get configmap/kube-proxy -o yaml | sed "s/127.0.0.1/0.0.0.0/" | ${root_path}/bin/ck8s ops kubectl sc replace -f -
${root_path}/bin/ck8s ops kubectl wc -n kube-system delete pod -l 'k8s-app=kube-proxy'
${root_path}/bin/ck8s ops kubectl sc -n kube-system delete pod -l 'k8s-app=kube-proxy'

echo ""
echo "OBS! To migrate the etcd fixes. ssh to master in both clusters then add"
echo "- --listen-metrics-urls=http://0.0.0.0:4001"
echo "To run arguments in /etc/kubernetes/manifests/etcd.yaml"