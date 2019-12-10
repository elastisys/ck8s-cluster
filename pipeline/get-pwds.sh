#!/bin/bash

# This scripts fetches the passwords from vault and exports them.

set -e

# Export grafana password
export GRAFANA_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/grafana" | jq -r '.data.data.password')

# Export harbor password
export HARBOR_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/harbor" | jq -r '.data.data.password')

# Export influxdb password
export INFLUXDB_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/influxdb" | jq -r '.data.data.password')

# Export kubelogin client secret for oauth
export KUBELOGIN_CLIENT_SECRET=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/kubelogin_client" | jq -r '.data.data.password')

# Export dashboard client secret for oauth
export DASHBOARD_CLIENT_SECRET=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/dashboard_client" | jq -r '.data.data.password')

# Export grafana client secret for oath
export GRAFANA_CLIENT_SECRET=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/grafana_client" | jq -r '.data.data.password')

# Export prometheus client secret
export PROMETHEUS_CLIENT_SECRET=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/prometheus_client" | jq -r '.data.data.password')

# Export customer prometheus client secret
export CUSTOMER_PROMETHEUS_CLIENT_SECRET=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/customer_prometheus_client" | jq -r '.data.data.password')
