INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo -e "\nTesting endpoints"

testEndpoint Prometheus https://prometheus.${ECK_C_DOMAIN}/

