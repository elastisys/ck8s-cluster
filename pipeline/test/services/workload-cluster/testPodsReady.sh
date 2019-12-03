INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

DEPLOYMENTS=(
    "kube-system oauth2-oauth2-proxy"
    "cert-manager cert-manager"
    "cert-manager cert-manager-cainjector"
    "cert-manager cert-manager-webhook"
    "kube-system coredns"
    "kube-system coredns-autoscaler"
    "kube-system kubernetes-dashboard"
    "kube-system kubernetes-metrics-scraper"
    "kube-system metrics-server"
    "nginx-ingress nginx-ingress-default-backend"
    "opa opa"
    "monitoring prometheus-operator-operator"
    "monitoring prometheus-operator-kube-state-metrics"
    "velero velero"
)

echo
echo
echo "Testing deployments"
echo "==================="

for DEPLOYMENT in "${DEPLOYMENTS[@]}"
do
    arguments=($DEPLOYMENT)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence deployment $DEPLOYMENT
    then
        testDeploymentStatus $DEPLOYMENT
    fi
done

DAEMONSETS=(
    "falco falco"
    "fluentd fluentd-fluentd-elasticsearch"
    "kube-system fluentd-system-fluentd-elasticsearch"
    "kube-system canal"
    "nginx-ingress nginx-ingress-controller"
    "monitoring prometheus-operator-prometheus-node-exporter"
    "velero restic"
)

echo
echo
echo "Testing daemonsets"
echo "=================="

for DAEMONSET in "${DAEMONSETS[@]}"
do
    arguments=($DAEMONSET)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence daemonset $DAEMONSET
    then
        testDaemonsetStatus $DAEMONSET
    fi
done

STATEFULSETS=(
    "monitoring prometheus-prometheus-operator-prometheus"
)

echo
echo
echo "Testing statefulsets"
echo "===================="

for STATEFULSET in "${STATEFULSETS[@]}"
do
    arguments=($STATEFULSET)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence statefulset $STATEFULSET
    then
        testStatefulsetStatus $STATEFULSET
    fi
done
