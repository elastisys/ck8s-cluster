#!/bin/bash

set -eu

if [ -f ~/.terraformrc ]; then
    echo "~/.terraformrc already exists. Skipping."
else
    echo 'credentials "app.terraform.io" {
      token = "'"${TF_TOKEN}"'"
    }' > ~/.terraformrc
fi

# TODO Remove when this is fixed https://github.com/actions/upload-artifact/issues/38
for file in ${CK8S_CONFIG_PATH}/.state/.terraform/plugins/linux_amd64/terraform-provider*; do
  if [ -f ${file} ]; then
    chmod +x ${file}
  fi
done
for file in ${CK8S_CONFIG_PATH}/.state/.terraform-tfe/plugins/linux_amd64/terraform-provider*; do
  if [ -f ${file} ]; then
    chmod +x ${file}
  fi
done
