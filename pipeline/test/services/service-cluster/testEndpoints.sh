INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing endpoints"
echo "=================="

GRAFANA_PWD=${GRAFANA_PWD:-"prom-operator"}
HARBOR_PWD=${HARBOR_PWD:-"Harbor12345"}
# Use fairly restricted metrics exporter user
ES_MX_PWD=$(kubectl get secrets -n elastic-system opendistro-es-metrics-exporter-user -o jsonpath="{.data.password}" | base64 -d)
ES_KB_PWD=$(kubectl get secrets -n elastic-system opendistro-es-kibanaserver-user -o jsonpath="{.data.password}" | base64 -d)

if [ "$ENABLE_HARBOR" == true ]; then
    testEndpoint Harbor https://harbor.${ECK_BASE_DOMAIN}/api/v2.0/users"" admin:${HARBOR_PWD}
fi

if [ "$ENABLE_CK8SDASH_SC" == true ]; then
    testEndpoint ck8sdash https://ck8sdash.${ECK_OPS_DOMAIN}/
fi

if [ $ENABLE_CUSTOMER_GRAFANA == "true" ]
then
    testEndpoint Grafana-customer https://grafana.${ECK_BASE_DOMAIN}/ admin:${CUSTOMER_GRAFANA_PWD}
fi

testEndpoint Grafana https://grafana.${ECK_OPS_DOMAIN}/ admin:${GRAFANA_PWD}

testEndpoint Elasticsearch https://elastic.${ECK_OPS_DOMAIN}/ metrics_exporter:${ES_MX_PWD}

testEndpoint Kibana https://kibana.${ECK_BASE_DOMAIN}/ kibanaserver:${ES_KS_PWD}