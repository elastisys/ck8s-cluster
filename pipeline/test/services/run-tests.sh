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

if [[ -z "${ENVIRONMENT_NAME}" ]]; then
  echo 'Missing ENVIRONMENT_NAME variable, insert environment variable (ex user-test):'
  read envVar
else
  envVar=$ENVIRONMENT_NAME
fi

# Create variables of commands
copyScCfg="cp $CONFIG_PATH/rke/kube_config_eck-sc.yaml $localPath/kube-bench/cfg/kube_config_eck-sc.yaml"
copyWcCfg="cp $CONFIG_PATH/rke/kube_config_eck-wc.yaml $localPath/kube-bench/cfg/kube_config_eck-wc.yaml"

createContainerScript=$(cat > $localPath/pipeline/test/services/container-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

# Give variables values if default value is not found (Inside container)
export CLOUD_PROVIDER=${CLOUD_PROVIDER:-"exoscale"}
export CUSTOMER_NAMESPACES=${CUSTOMER_NAMESPACES:-"demo1 demo2 demo3"}
export CUSTOMER_ADMIN_USERS=${CUSTOMER_ADMIN_USERS:-"admin@example.com"}
export ECK_OPS_DOMAIN=${ECK_OPS_DOMAIN:-"ops.$envVar.a1ck.io"}
export ECK_BASE_DOMAIN=${ECK_BASE_DOMAIN:-"$envVar.a1ck.io"}
export ENABLE_CUSTOMER_GRAFANA=${ENABLE_CUSTOMER_GRAFANA:-"false"}

# Create variables of commands (Inside container)
exportScCfg="export KUBECONFIG=/home/ck8s/kube-bench/cfg/kube_config_eck-sc.yaml"
runScTest="bash /home/ck8s/pipeline/test/services/test-sc.sh"
exportWcCfg="export KUBECONFIG=/home/ck8s/kube-bench/cfg/kube_config_eck-wc.yaml"
runWcTest="bash /home/ck8s/pipeline/test/services/test-wc.sh"

# Execute commands in the right order (Inside container)
eval $exportScCfg
eval $runScTest
eval $exportWcCfg
eval $runWcTest
EOF)

makeExec="chmod +x $localPath/pipeline/test/services/container-entrypoint.sh"
dockerRun="docker run -it -v $localPath:/home/ck8s --entrypoint=/home/ck8s/pipeline/test/services/container-entrypoint.sh elastisys/ck8s-ops:$repoTag"

# Execute commands in the right order
eval $copyScCfg
eval $copyWcCfg
eval $createContainerScript
eval $makeExec
eval $dockerRun