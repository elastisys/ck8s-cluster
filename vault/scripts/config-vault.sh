#!/bin/bash

set -e

: "${ECK_VAULT_DOMAIN:?Missing ECK_VAULT_DOMAIN}"
: "${VAULT_TOKEN:?Missing VAULT_TOKEN}"

# Enable the kv (v1) secrets engine at path 'secret/'.
tee payload.json <<EOF
{
  "type": "kv",
  "options": {
    "version": "1"
  }
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
       --request POST \
       --data @payload.json \
       "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/mounts/secret"

# Enable approle authentication
curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    https://vault.${ECK_VAULT_DOMAIN}/v1/sys/auth/approle

# Create ACL policy for creating/reading secrets in 'secret/customer/*'.
tee payload.json <<EOF
{
  "policy": "path \"secret/customer/*\" {capabilities = [\"create\",\"read\",\"list\"]}"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @payload.json \
    "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/policy/customer-rw"

# Create approle 'customer-rw', associate it with the customer-rw policy.
curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"policies": ["customer-rw"]}' \
    "https://vault.${ECK_VAULT_DOMAIN}/v1/auth/approle/role/customer-rw"
