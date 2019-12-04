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

testEndpoint Harbor https://harbor.${ECK_BASE_DOMAIN}/api/users"" admin:${HARBOR_PWD}

testEndpoint Grafana https://grafana.${ECK_BASE_DOMAIN}/ admin:${GRAFANA_PWD}
