INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing endpoints"
echo "=================="

GRAFANA_PWD=${GRAFANA_PWD:-"prom-operator"}
HARBOR_PWD=${HARBOR_PWD:-"Harbor12345"}

PW=$(kubectl get secrets -n elastic-system elasticsearch-es-elastic-user -o jsonpath="{.data.elastic}" | base64 -d)

testEndpoint Elasticsearch https://elastic.${ECK_OPS_DOMAIN}/ elastic:${PW}

testEndpoint Kibana https://kibana.${ECK_BASE_DOMAIN}/ elastic:${PW}

if [ "$ENABLE_HARBOR" == true ]; then
    testEndpoint Harbor https://harbor.${ECK_BASE_DOMAIN}/api/users"" admin:${HARBOR_PWD}
fi

testEndpoint Grafana https://grafana.${ECK_OPS_DOMAIN}/ admin:${GRAFANA_PWD}

if [ "$ENABLE_CK8SDASH_SC" == true ]; then
    testEndpoint ck8sdash https://ck8sdash.${ECK_OPS_DOMAIN}/
fi

if [ $ENABLE_CUSTOMER_GRAFANA == "true" ]
then
    testEndpoint Grafana-customer https://grafana.${ECK_BASE_DOMAIN}/ admin:${CUSTOMER_GRAFANA_PWD}
fi
