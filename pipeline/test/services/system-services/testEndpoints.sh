INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo -e "\nTesting endpoints"

PW=$(kubectl get secrets -n elastic-system elasticsearch-es-elastic-user -o jsonpath="{.data.elastic}" | base64 -d)

testEndpoint Elasticsearch https://elastic.${ECK_SS_DOMAIN}/ elastic:${PW}

testEndpoint Kibana https://kibana.${ECK_SS_DOMAIN}/ elastic:${PW}

testEndpoint Harbor https://harbor.${ECK_SS_DOMAIN}/ admin:Harbor12345

testEndpoint Grafana https://grafana.${ECK_SS_DOMAIN}/ admin:prom-operator

