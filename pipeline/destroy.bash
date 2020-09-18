#!/bin/bash

ckctl destroy --cluster sc
sc_code=$?
ckctl destroy --cluster wc
wc_code=$?

if [ ${sc_code} -eq 0 ] && [ ${wc_code} -eq 0 ]
then
    set -e
    ckctl destroy --cluster sc --destroy-remote-workspace
else
    echo "Failed to destroy some resources. Terraform workspace will not be deleted"
    exit 1
fi
