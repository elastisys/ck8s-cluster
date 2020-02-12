set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
echo "Sourcing variables"
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"

echo "Initializing vault usage"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
source pipeline/variables.sh

source ./scripts/post-infra-common.sh infra.json
export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml

echo "running deploy-sc.sh" 
./scripts/deploy-sc.sh > "${GITHUB_WORKSPACE}/deploy-sc-output"
kubectl get pods --all-namespaces
kubectl get nodes

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
echo "Deploy sc completed!"