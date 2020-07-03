INNER_SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
source ${INNER_SCRIPTS_PATH}/../funcs.sh

echo
echo
echo "Testing endpoints"
echo "=================="

testEndpoint Prometheus-wc https://prometheus.${ECK_BASE_DOMAIN}/ prometheus:${CUSTOMER_PROMETHEUS_PWD}
if [ $ENABLE_CUSTOMER_ALERTMANAGER_INGRESS == "true" ]
then
    testEndpoint Alertmanager-customer https://alertmanager.${ECK_BASE_DOMAIN}/ alertmanager:${CUSTOMER_ALERTMANAGER_PWD}
fi

if [ $ENABLE_CK8SDASH_WC == "true" ]; then
    testEndpoint ck8sdash https://ck8sdash.${ECK_BASE_DOMAIN}/
fi
