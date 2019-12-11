INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing endpoints"
echo "=================="

testEndpoint Prometheus https://prometheus.${ECK_BASE_DOMAIN}/ prometheus:${PROMETHEUS_CLIENT_SECRET}
