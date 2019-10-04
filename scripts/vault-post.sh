#!/bin/bash

# This script is a simple wrapper for posting secrets to vault.

##########################################
#### The payload is taken from STDIN! ####
##########################################

# Some benefits.
# 1. Secrets don't appear in bash history.
# 2. Allows you to do pre-processing of secrets, e.g. cat file | base64 | vault-post.sh...

set -e

if [[ "$#" -lt 3 ]]
then 
  >&2 echo "Usage: <echo "supersecret"> | vault-post.sh vault_addr vault_token path"
  exit 1
fi

vault_addr="$1"
vault_token="$2"
path="$3"

curl -s -k \
    --header "X-Vault-Token: $vault_token" \
    --request POST \
    --data @- \
    "$vault_addr"/v1/"$path"
