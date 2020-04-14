#/bin/bash
# This script is for adding the new terraform config file to your config repo.
set -e
: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

here="$(dirname "$(readlink -f "$BASH_SOURCE")")"
root_path="${here}/../.."
config_defaults_path="${root_path}/config"
backend_config="$CK8S_CONFIG_PATH/backend_config.hcl"
source "${root_path}/bin/common.bash"
source "${config[config_file]}"

if [ "${CLOUD_PROVIDER}" == "exoscale" ]; then
      export TERRAFORM_PREFIX="a1-demo-"
  elif [ "${CLOUD_PROVIDER}" == "safespring" ]; then
      export TERRAFORM_PREFIX="safespring-demo-"
  elif [ "${CLOUD_PROVIDER}" == "citycloud" ]; then
      export TERRAFORM_PREFIX="citycloud-"
  elif [ "${CLOUD_PROVIDER}" == "aws" ]; then
      export TERRAFORM_PREFIX="aws-"
  else
      echo "ERROR: invalid name of CLOUD_PROVIDER=${CLOUD_PROVIDER}"
      exit 1
  fi

if [[ -f "$backend_config" ]]; then
    echo "ERROR: file $backend_config already exists"
    exit 1
fi
cat "${config_defaults_path}/terraform/backend_config.hcl"\
     | envsubst > "${CK8S_CONFIG_PATH}/backend_config.hcl"

echo "Config migrated to ${CK8S_CONFIG_PATH}/backend_config.hcl"