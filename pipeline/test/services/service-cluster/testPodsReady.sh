: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing deployments"
echo "==================="

deployments=(
    "dex dex"
    "cert-manager cert-manager"
    "cert-manager cert-manager-cainjector"
    "cert-manager cert-manager-webhook"
    "elastic-system kibana-kb"
    "kube-system calico-kube-controllers"
    "kube-system coredns"
    "kube-system metrics-server"
    "nginx-ingress nginx-ingress-default-backend"
    "monitoring customer-grafana"
    "monitoring prometheus-operator-operator"
    "monitoring prometheus-operator-grafana"
    "monitoring prometheus-operator-kube-state-metrics"
    "monitoring blackbox-prometheus-blackbox-exporter"
    "fluentd fluentd-aggregator"
    "velero velero"
)
if [ $CLOUD_PROVIDER == "exoscale" ]
then
    deployments+=("kube-system nfs-client-provisioner")
fi
if [ "$ENABLE_HARBOR" == true ]; then
    deployments+=(
        "harbor harbor-harbor-chartmuseum"
        "harbor harbor-harbor-clair"
        "harbor harbor-harbor-core"
        "harbor harbor-harbor-jobservice"
        "harbor harbor-harbor-notary-server"
        "harbor harbor-harbor-notary-signer"
        "harbor harbor-harbor-portal"
        "harbor harbor-harbor-registry"
    )
fi
if [ "$ENABLE_CK8SDASH_SC" == true ]; then
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
    "kube-system calico-node"
    "kube-system node-local-dns"
    "nginx-ingress nginx-ingress-controller"
    "monitoring prometheus-operator-prometheus-node-exporter"
    "fluentd fluentd"
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
    "monitoring prometheus-wc-scraper-prometheus-instance"
    "monitoring alertmanager-prometheus-operator-alertmanager"
    "elastic-system elastic-operator"
    "influxdb-prometheus influxdb"
)
if [ "$ENABLE_HARBOR" == true ]; then
    statefulsets+=(
        "harbor harbor-harbor-database"
        "harbor harbor-harbor-redis"
    )
fi

resourceKind="StatefulSet"
# Get json data in a smaller dataset
simpleData="$(getStatus $resourceKind)"
for statefulset in "${statefulsets[@]}"
do
    testResourceExistenceFast ${resourceKind} $statefulset "${simpleData}"
done

# elasticsearch-es-nodes has update strategy OnDelete.
# Therefore `kubectl rollout status` which is used in the other test doesn't
# work
STATEFULSET="elastic-system elasticsearch-es-nodes"
echo -n -e "\nelasticsearch-es-nodes\t"
if testResourceExistence statefulset $STATEFULSET; then
    testStatefulsetStatusByPods $STATEFULSET
fi

# Format:
# namespace job-name timeout
JOBS=(
  "elastic-system configure-es-job 120s"
)
if [ "$ENABLE_HARBOR" == true ]; then
    JOBS+=(
        "harbor init-harbor-job 120s"
    )
fi

echo
echo
echo "Testing jobs"
echo "===================="

for JOB in "${JOBS[@]}"
do
    arguments=($JOB)
    echo -n -e "\n${arguments[1]}\t"
    if testResourceExistence job $JOB
    then
        testJobStatus $JOB
    fi
done

# Format:
# namespace cronjob-name timeout
CRONJOBS=(
  "influxdb-prometheus influxdb-metrics-retention-cronjob"
  "influxdb-prometheus influxdb-backup"
  "elastic-system curator"
)

echo
echo
echo "Testing cronjobs"
echo "===================="

for CRONJOB in "${CRONJOBS[@]}"
do
    arguments=($CRONJOB)
    echo -n -e "\n${arguments[1]}\t"
    testResourceExistence cronjob $CRONJOB
done

echo
echo
echo "Testing other services"
echo "======================"

echo -n -e "\nelasticsearch\t"
# This checks the health status of the elasticsearch custom resource
retries=5
while true; do
    RES=$(kubectl -n elastic-system get elasticsearches.elasticsearch.k8s.elastic.co -o jsonpath="{.items[0].status.health}")

    retries=$((retries - 1))

    [ "${retries}" -lt 1 ] || [ "${RES}" = "green" ] && break

    echo "health not green yet, retrying..."
    echo -n -e "elasticsearch\t"

    sleep 10
done
if [[ $RES == "green" ]]
then echo -n -e "\tready ✔"; SUCCESSES=$((SUCCESSES+1))
else echo -n -e "\tnot ready ❌"; FAILURES=$((FAILURES+1))
fi
