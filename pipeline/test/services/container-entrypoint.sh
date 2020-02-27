#!/bin/bash
set -e

# Give variables values if default value is not found
export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"exoscale"}
export CUSTOMER_NAMESPACES=${CUSTOMER_NAMESPACES:-"demo1 demo2 demo3"}
export CUSTOMER_ADMIN_USERS=${CUSTOMER_ADMIN_USERS:-"admin@example.com"}
export ECK_OPS_DOMAIN=${ECK_OPS_DOMAIN:-"ops.$ENVIRONMENT_NAME.a1ck.io"}
export ECK_BASE_DOMAIN=${ECK_BASE_DOMAIN:-"$ENVIRONMENT_NAME.a1ck.io"}
export ENABLE_CUSTOMER_GRAFANA=${ENABLE_CUSTOMER_GRAFANA:-"false"}

# Execute commands
export KUBECONFIG=$CONFIG_PATH/rke/kube_config_eck-sc.yaml
bash $CK8S/pipeline/test/services/test-sc.sh || true
export KUBECONFIG=$CONFIG_PATH/rke/kube_config_eck-wc.yaml
bash $CK8S/pipeline/test/services/test-wc.sh