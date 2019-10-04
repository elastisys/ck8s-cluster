#!/bin/bash

set -e

: "${ECK_VAULT_DOMAIN:?Missing ECK_VAULT_DOMAIN}"
: "${VAULT_TOKEN:?Missing VAULT_TOKEN}"

# Enable the kv (v2) secrets engine at path 'eck/'.
tee payload.json <<EOF
{
  "type": "kv",
  "options": {
    "version": "2"
  }
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
       --request POST \
       --data @payload.json \
       "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/mounts/eck"

# Set max versions to 5.
tee payload.json<<EOF
{
  "max_versions": 5,
  "cas_required": false
}
EOF

curl -k --header "X-Vault-Token: $VAULT_TOKEN" \
       --request POST \
       --data @payload.json \
       "https://vault.${ECK_VAULT_DOMAIN}/v1/eck/config"

# Enable approle authentication
curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data '{"type": "approle"}' \
    "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/auth/approle"

# Create ACL policy that grants ALL ACCESS on 'eck/*'.
tee payload.json <<EOF
{
  "policy": "path \"eck/*\" {capabilities = [\"create\",\"read\",\"update\",\"delete\",\"list\"]}"
}
EOF

curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request PUT \
    --data @payload.json \
    "https://vault.${ECK_VAULT_DOMAIN}/v1/sys/policy/eck-aa"

tee payload.json <<EOF
{
  "token_ttl": "30m",
  "token_max_ttl": "45m",
  "token_policies": [
    "eck-aa"
  ],
  "period": 0,
  "bind_secret_id": true
}
EOF

# Create approle 'pipeline', associate it with the 'eck-aa' policy.
curl -k \
    --header "X-Vault-Token: $VAULT_TOKEN" \
    --request POST \
    --data @payload.json \
    "https://vault.${ECK_VAULT_DOMAIN}/v1/auth/approle/role/pipeline"
