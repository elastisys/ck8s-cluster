INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing endpoints"
echo "=================="

testEndpoint Prometheus-wc https://prometheus.${ECK_BASE_DOMAIN}/ prometheus:${PROMETHEUS_CLIENT_SECRET}
if [ $ENABLE_CUSTOMER_PROMETHEUS == "true" ]
then
    testEndpoint Prometheus-customer https://scrape.${ECK_BASE_DOMAIN}/ prometheus:${CUSTOMER_PROMETHEUS_CLIENT_SECRET}
fi
if [ $ENABLE_CUSTOMER_ALERTMANAGER == "true" ]
then
    testEndpoint Alertmanager-customer https://alertmanager.${ECK_BASE_DOMAIN}/ alertmanager:${CUSTOMER_ALERTMANAGER_CLIENT_SECRET}
fi
testEndpoint ck8sdash https://ck8sdash.${ECK_BASE_DOMAIN}/
