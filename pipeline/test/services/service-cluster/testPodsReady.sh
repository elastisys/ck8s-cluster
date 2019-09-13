INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

DEPLOYMENTS=(
    "dex dex"
    "kube-system oauth2-oauth2-proxy"
    "cert-manager cert-manager"
    "cert-manager cert-manager-cainjector"
    "cert-manager cert-manager-webhook"
    "elastic-system kibana-kb"
    "harbor harbor-harbor-chartmuseum"
    "harbor harbor-harbor-clair"
    "harbor harbor-harbor-core"
    "harbor harbor-harbor-jobservice"
    "harbor harbor-harbor-notary-server"
    "harbor harbor-harbor-notary-signer"
    "harbor harbor-harbor-portal"
    "harbor harbor-harbor-registry"
    "kube-system coredns"
    "kube-system coredns-autoscaler"
    "kube-system kubernetes-dashboard"
    "kube-system kubernetes-metrics-scraper"
    "kube-system metrics-server"
    "kube-system nfs-client-provisioner"
    "ingress-nginx default-http-backend"
    "monitoring prometheus-operator-operator"
    "monitoring prometheus-operator-grafana"
    "monitoring prometheus-operator-kube-state-metrics"
    "influxdb-prometheus influxdb"
)

echo -e "\nTesting deployments"

for DEPLOYMENT in "${DEPLOYMENTS[@]}"
do
    testDeploymentStatus $DEPLOYMENT
done 

DAEMONSETS=(
    "kube-system canal"
    "ingress-nginx nginx-ingress-controller"
    "monitoring prometheus-operator-prometheus-node-exporter"
)

echo -e "\nTesting daemonsets"

for DAEMONSET in "${DAEMONSETS[@]}"
do
    testDaemonsetStatus $DAEMONSET
done 

STATEFULSETS=(
    "monitoring prometheus-prometheus-operator-prometheus"
    "monitoring prometheus-prometheus-c-reader"
    "monitoring alertmanager-prometheus-operator-alertmanager"
    "elastic-system elastic-operator"
    "harbor harbor-harbor-database"
    "harbor harbor-harbor-redis"
)

echo -e "\nTesting statefulsets"

for STATEFULSET in "${STATEFULSETS[@]}"
do
    testStatefulsetStatus $STATEFULSET
done

echo -e "\nTesting other pods"
echo elasticsearch
# The following command looks at the status conditions for the elasticsearch pods.
# It assumes that the "Ready" condition is the second condition in the list, 
# if that is somehow wrong then this test will fail.
# It also assumes that there is supposed to be three pods.
RES=$(kubectl get pods -n elastic-system -l common.k8s.elastic.co/type=elasticsearch -o jsonpath="{.items[*].status.conditions[1].type},{.items[*].status.conditions[1].status}")
if [[ $RES == "Ready Ready Ready,True True True" ]]
then echo "ready"; SUCCESSES=$((SUCCESSES+1))
else echo "not ready"; FAILURES=$((FAILURES+1))
fi