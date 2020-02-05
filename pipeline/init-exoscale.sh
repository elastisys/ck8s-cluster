#!/bin/bash
export TF_IN_AUTOMATION="true"
export TF_VAR_exoscale_api_key=$EXOSCALE_API_KEY
export TF_VAR_exoscale_secret_key=$EXOSCALE_SECRET_KEY

#export GOOGLE_CLIENT_ID=asd
#export GOOGLE_CLIENT_SECRET=asd
echo "credentials \"app.terraform.io\" {
  token = \"${TF_TOKEN}\"
}" > ~/.terraformrc