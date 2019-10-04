#!/bin/bash

# This scripts fetches the passwords from vault and exports them.

set -e

# Export grafana password
export GRAFANA_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/grafana" | jq -r '.data.data.password')

# Export harbor password
export HARBOR_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/harbor" | jq -r '.data.data.password')

# Export influxdb password
export INFLUXDB_PWD=$(./scripts/vault-get.sh "$VAULT_ADDR" "$VAULT_TOKEN" "$BASE_PATH/influxdb" | jq -r '.data.data.password')