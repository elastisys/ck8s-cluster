#!/bin/bash

# Assumes kubeconfig has been correctly set.
# Assumes that the vault pod is running.
# Will store keys and root token in path where scripts was called.

: "${KUBECONFIG:?Missing KUBECONFIG}"
: "${ECK_VAULT_DOMAIN:?Missing ECK_VAULT_DOMAIN}"

# Initialize vault. 3 master key shards. 
response=$(curl -k -s --request PUT --data '{"secret_shares": 3, "secret_threshold": 2}' "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/init")
initialized=$(echo $response | jq '.errors')

# Unseal if not already initialized.
if [[ $initialized == "null" ]]
then 
  keys=($(echo $response | jq '.keys[]'))
  root_token=$(echo $response | jq '.root_token')

  # Unseal vaul using the 2 first keys.
  curl -s -k \
    --request POST \
    --data '{"key": '"${keys[0]}"'}' \
    https://vault.${ECK_VAULT_DOMAIN}/v1/sys/unseal > /dev/null

  curl -s -k \
    --request POST \
    --data '{"key": '"${keys[1]}"'}' \
    https://vault.${ECK_VAULT_DOMAIN}/v1/sys/unseal > /dev/null

elif [[ $initialized == *"Vault is already initialized"* ]]
then
  echo "Vault is already initialized."
fi

keys_token=$(echo $response | jq '{"keys": .keys, "root_token": .root_token}')

echo $keys_token

# helmfile -f helmfile/helmfile.yaml -e vault_cluster -l app=vault destroy;kubectl delete pvc -n vault data-vault-0;helmfile -f helmfile/helmfile.yaml -e vault_cluster -l app=vault apply;sleep 5;kubectl port-forward -n vault vault-0 8200:8200
