INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo -e "\nTesting endpoints"

GRAFANA_PWD=${GRAFANA_PWD:-"prom-operator"}
HARBOR_PWD=${HARBOR_PWD:-"Harbor12345"}

PW=$(kubectl get secrets -n elastic-system elasticsearch-es-elastic-user -o jsonpath="{.data.elastic}" | base64 -d)

testEndpoint Elasticsearch https://elastic.${ECK_SC_DOMAIN}/ elastic:${PW}

testEndpoint Kibana https://kibana.${ECK_SC_DOMAIN}/ elastic:${PW}

testEndpoint Harbor https://harbor.${ECK_SC_DOMAIN}/api/users"" admin:${HARBOR_PWD}

testEndpoint Grafana https://grafana.${ECK_SC_DOMAIN}/ admin:${GRAFANA_PWD}
