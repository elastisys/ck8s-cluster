#!/bin/bash
set -e

# Script that runs service cluster and worker cluster tests on a local container

# Requests user inputs or exits script if variable does not exist
if [ "${1}" == "" ]; then
  echo 'Error: no argument found'
  echo 'Insert the docker image tag as an argument when running the script (ex ./run-tests.sh v0.1.0-dev)'
  exit 2
fi

if [[ -z "${CK8S}" ]]; then
  echo 'Missing CK8S variable, insert local path to repository (ex /home/user/ck8s):'
  read CK8S
fi

if [[ -z "${CONFIG_PATH}" ]]; then
  echo 'Missing CONFIG_PATH variable, insert local path to eck config files (ex /home/user/ck8s-config):'
  read CONFIG_PATH
fi

if [[ -z "${ENVIRONMENT_NAME}" ]]; then
  echo 'Missing ENVIRONMENT_NAME variable, insert environment variable (ex user-test):'
  read ENV_NAME
  export ENVIRONMENT_NAME="${ENV_NAME}"
fi

# run container with entrypoint script and env variables
docker run -it -v "${CK8S}:/ck8s" \
-v "${CONFIG_PATH}:/ck8s-config" \
--entrypoint=/ck8s/pipeline/test/services/docker/container-entrypoint.sh \
-e CK8S=/ck8s \
-e CONFIG_PATH=/ck8s-config \
-e ENVIRONMENT_NAME="${ENVIRONMENT_NAME}" \
-e CLOUD_PROVIDER="${CLOUD_PROVIDER}" \
-e CUSTOMER_NAMESPACES="${CUSTOMER_NAMESPACES}" \
-e CUSTOMER_ADMIN_USERS="${CUSTOMER_ADMIN_USERS}" \
-e ECK_OPS_DOMAIN="${ECK_OPS_DOMAIN}" \
-e ECK_BASE_DOMAIN="${ECK_BASE_DOMAIN}" \
-e ENABLE_CUSTOMER_GRAFANA="${ENABLE_CUSTOMER_GRAFANA}" \
-e ENABLE_CUSTOMER_ALERTMANAGER="${ENABLE_CUSTOMER_ALERTMANAGER}" \
-e ENABLE_CUSTOMER_PROMETHEUS="${ENABLE_CUSTOMER_PROMETHEUS}" \
elastisys/ck8s-ops:"${1}"