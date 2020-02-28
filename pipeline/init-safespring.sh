#!/bin/bash
export TF_IN_AUTOMATION="true"

export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://keystone.api.cloud.ipnett.se/v3
export OS_PROJECT_DOMAIN_NAME=elastisys.se
export OS_USER_DOMAIN_NAME=elastisys.se
export OS_PROJECT_NAME=ck8s-demo.elastisys.se
export OS_REGION_NAME=se-east-1
export OS_PROJECT_ID=add72b7b2ed644a8842b1784dbdf275f

echo "credentials \"app.terraform.io\" {
  token = \"${TF_TOKEN}\"
}" > ~/.terraformrc
