#!/bin/bash

if [ "$BITBUCKET_EXIT_CODE" == "0" ]
then 
    exit 0
fi
source pipeline/init.sh
export TF_VAR_dns_prefix=pipeline-$BITBUCKET_BUILD_NUMBER
cd terraform/
echo '1' | TF_WORKSPACE=pipeline terraform init
terraform workspace select pipeline-$BITBUCKET_BUILD_NUMBER
terraform destroy -auto-approve
terraform workspace select pipeline
terraform workspace delete pipeline-$BITBUCKET_BUILD_NUMBER