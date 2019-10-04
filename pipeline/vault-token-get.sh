#!/bin/bash

# This scripts generates a client token to use with vault.

set -e

# Cannot be executed in the pipeline directly.
curl -k -s --request POST --data '{"role_id": "'"$VAULT_APPROLE_RID"'", "secret_id": "'"$VAULT_APPROLE_SID"'"}' "${VAULT_ADDR}/v1/auth/approle/login" | jq -r '.auth.client_token'