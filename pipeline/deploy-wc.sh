set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
echo "sourcing variables"
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"

echo "getting vault passwords"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
source pipeline/variables.sh

source ./scripts/post-infra-common.sh infra.json
export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
echo "running deploy-wc.sh"
./scripts/deploy-wc.sh > "${GITHUB_WORKSPACE}/deploy-wc-output"
kubectl get pods --all-namespaces
kubectl get nodes

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
echo "Deploy wc completed!"