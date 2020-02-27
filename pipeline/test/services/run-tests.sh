#!/bin/bash
set -e

# Script that runs service cluster and worker cluster tests on a local container

# Requests user inputs or exits script if variable does not exist
if [ "$1" == "" ]; then
  echo 'Error: no argument found'
  echo 'Insert the docker image tag as an argument when running the script (ex ./run-tests.sh v0.1.0-dev)'
  exit 2
fi

if [[ -z "${CK8S}" ]]; then
  echo 'Missing CK8S variable, insert local path to repository (ex /home/user/ck8s):'
  read CK8S
fi

if [[ -z "${CONFIG_PATH}" ]]; then
  echo 'Missing CONFIG_PATH variable, insert local path to eck config files:'
  read CONFIG_PATH
fi

if [[ -z "${ENVIRONMENT_NAME}" ]]; then
  echo 'Missing ENVIRONMENT_NAME variable, insert environment variable (ex user-test):'
  read ENV_NAME
  export ENVIRONMENT_NAME=$ENV_NAME
fi

# run container with entrypoint script
docker run -it -v "${CK8S}:${CK8S}" -v "${CONFIG_PATH}:${CONFIG_PATH}" --entrypoint=$CK8S/pipeline/test/services/container-entrypoint.sh -e=CK8S=$CK8S -e=CONFIG_PATH=$CONFIG_PATH -e=ENVIRONMENT_NAME=$ENVIRONMENT_NAME elastisys/ck8s-ops:$1