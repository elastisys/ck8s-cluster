#!/bin/bash
export SSH_PATH=~/.ssh/id_rsa
export TF_IN_AUTOMATION="true"
export TF_VAR_ssh_pub_key_file_sc=${SSH_PATH}.pub
export TF_VAR_ssh_pub_key_file_wc=${SSH_PATH}.pub

export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://keystone.api.cloud.ipnett.se/v3
export OS_PROJECT_DOMAIN_NAME=elastisys.se
export OS_USER_DOMAIN_NAME=elastisys.se
export OS_PROJECT_NAME=infra.elastisys.se
export OS_REGION_NAME=se-east-1
export OS_PROJECT_ID=9f91e56185fb4f929c36430ac4bcbe6e

export CLOUD_PROVIDER=safespring

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
