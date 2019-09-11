#!/bin/bash
export SSH_PATH=~/.ssh/id_rsa
export TF_IN_AUTOMATION="true"
export TF_VAR_ssh_pub_key_file_system_services=${SSH_PATH}.pub
export TF_VAR_ssh_pub_key_file_customer=${SSH_PATH}.pub
export TF_VAR_exoscale_api_key=$EXOSCALE_API_KEY
export TF_VAR_exoscale_secret_key=$EXOSCALE_SECRET_KEY
#export GOOGLE_CLIENT_ID=asd
#export GOOGLE_CLIENT_SECRET=asd
export CERT_TYPE=staging
eval `ssh-agent`
cp /opt/atlassian/pipelines/agent/ssh/id_rsa $SSH_PATH
ssh-keygen -y -f $SSH_PATH -N '' > ${SSH_PATH}.pub
ssh-add $SSH_PATH
echo "credentials \"app.terraform.io\" {
  token = \"${TF_TOKEN}\"
}" > ~/.terraformrc
