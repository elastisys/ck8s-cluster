#!/bin/bash
set -e

# Script that runs service cluster and worker cluster tests on a local container

# Requests user inputs or exits script if variable does not exist
if [ "$1" != "" ]; then
  repoTag=$1
else
  echo 'Error: no argument found'
  echo 'Insert the docker image tag as an argument when running the script (ex ./run-tests.sh v0.1.0-dev)'
  bash $localPath/pipeline/test/services/run-tests.sh
fi

if [[ -z "${CONFIG_PATH}" ]]; then
  echo 'Error: missing CONFIG_PATH variable'
  exit 2
fi

if [[ -z "${CK8S}" ]]; then
  echo 'Missing CK8S variable, insert local path to repository (ex /home/user/ck8s):'
  read localPath
else
  localPath=$CK8S
fi

if [[ -z "${CONFIG_PATH}" ]]; then
  echo 'Missing CONFIG_PATH variable, insert local path to config files:'
  read cfgPath
else
  cfgPath=$CONFIG_PATH
fi

if [[ -z "${ENVIRONMENT_NAME}" ]]; then
  echo 'Missing ENVIRONMENT_NAME variable, insert environment variable (ex user-test):'
  read envVar
else
  envVar=$ENVIRONMENT_NAME
fi

# run container with entrypoint script
docker run -it -v $localPath:$localPath --entrypoint=$localPath/pipeline/test/services/container-entrypoint.sh -e=cfgPath=$CONFIG_PATH -e=localPath=$CK8S elastisys/ck8s-ops:$repoTag