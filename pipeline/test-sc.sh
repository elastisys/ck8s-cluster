set -e

echo "sourcing variables"
export CLOUD_PROVIDER=exoscale
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"

echo "getting vault passwords"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh
source pipeline/variables.sh

source ./scripts/post-infra-common.sh infra.json
export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
echo "testing deploy-wc.sh"
./pipeline/test/services/test-wc.sh

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"