#!/bin/bash

if [ "$BITBUCKET_EXIT_CODE" == "0" ]
then
    exit 0
fi

if [[ "$#" -lt 1 ]]
then
  >&2 echo "Usage: after-script.sh <init-script>"
  exit 1
fi

# Run init script
source $1

# Export vault variables
source pipeline/vault-variables.sh

# Export vault token
export VAULT_TOKEN=$(cat vault-token.txt)

# Revoke vault token, remove password secrets for services
./pipeline/vault-cleanup.sh grafana harbor influxdb kubelogin_client dashboard_client grafana_client prometheus_client customer_prometheus_client

export TF_VAR_dns_prefix=pipeline-$BITBUCKET_BUILD_NUMBER
if [ "$CLOUD_PROVIDER" == "exoscale" ]
then
    cd terraform/exoscale
elif [ "$CLOUD_PROVIDER" == "safespring" ]
then
    cd terraform/safespring
fi
echo '1' | TF_WORKSPACE=pipeline terraform init
terraform workspace select pipeline-$BITBUCKET_BUILD_NUMBER
terraform destroy -auto-approve
terraform workspace select pipeline
terraform workspace delete pipeline-$BITBUCKET_BUILD_NUMBER
