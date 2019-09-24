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