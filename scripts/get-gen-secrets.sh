#!/bin/bash

declare -A env_vars
env_vars=(
    ["harbor"]="HARBOR_PWD"
    ["grafana"]="GRAFANA_PWD"
    ["influxdb"]="INFLUXDB_PWD"
    ["kubelogin_client"]="KUBELOGIN_CLIENT_SECRET"
    ["grafana_client"]="GRAFANA_CLIENT_SECRET"
    ["dashboard_client"]="DASHBOARD_CLIENT_SECRET"
)

for key in ${!env_vars[@]}
do
    unset password
    # Get password from vault
    password=$(vault kv get -field=password eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${key})
    if [ -z ${password} ]
    then
        # No password in vault, generate a new one and store
        echo "Generating password for ${env_vars[$key]}"
        password="$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c20)"
        vault kv put eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${key} password=${password}
    fi
    export ${env_vars[$key]}=${password}
done
