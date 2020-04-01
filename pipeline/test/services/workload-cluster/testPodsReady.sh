: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing deployments"
echo "==================="

deployments=(
    "cert-manager cert-manager"
    "cert-manager cert-manager-cainjector"
    "cert-manager cert-manager-webhook"
    "kube-system coredns"
    "kube-system metrics-server"
    "kube-system calico-kube-controllers"
    "nginx-ingress nginx-ingress-default-backend"
    "opa opa"
    "monitoring prometheus-operator-operator"
    "monitoring prometheus-operator-kube-state-metrics"
    "velero velero"
    "falco falcosidekick"
)
if [ $CLOUD_PROVIDER == "exoscale" ]; then
    deployments+=("kube-system nfs-client-provisioner")
fi
if [ "$ENABLE_CK8SDASH_WC" == true ]; then
    deployments+=("ck8sdash ck8sdash")
fi

resourceKind="Deployment"
# Get json data in a smaller dataset
simpleData="$(getStatus $resourceKind)"
for deployment in "${deployments[@]}"
do
    testResourceExistenceFast ${resourceKind} $deployment "${simpleData}"
done

echo
echo
echo "Testing daemonsets"
echo "=================="

daemonsets=(
    "falco falco"
    "fluentd fluentd-fluentd-elasticsearch"
    "kube-system calico-node"
    "kube-system fluentd-system-fluentd-elasticsearch"
    "kube-system node-local-dns"
    "nginx-ingress nginx-ingress-controller"
    "monitoring prometheus-operator-prometheus-node-exporter"
    "velero restic"
)

resourceKind="DaemonSet"
# Get json data in a smaller dataset
simpleData="$(getStatus $resourceKind)"
for daemonset in "${daemonsets[@]}"
do 
    testResourceExistenceFast ${resourceKind} $daemonset "${simpleData}"
done

echo
echo
echo "Testing statefulsets"
echo "===================="

statefulsets=(
    "monitoring prometheus-prometheus-operator-prometheus"
)
set -- ${CUSTOMER_NAMESPACES}
CONTEXT_NAMESPACE=$1
if [[ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]]
then
    statefulsets+=("$CONTEXT_NAMESPACE alertmanager-alertmanager")
fi

resourceKind="StatefulSet"
# Get json data in a smaller dataset
simpleData="$(getStatus $resourceKind)"
for statefulset in "${statefulsets[@]}"
do
    testResourceExistenceFast ${resourceKind} $statefulset "${simpleData}"
done