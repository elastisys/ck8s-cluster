set -e

echo "sourcing variables"
export CLOUD_PROVIDER=safespring
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source pipeline/init-safespring.sh
source pipeline/init-ssh.sh
export TF_VAR_dns_prefix="pipeline-$GITHUB_RUN_ID"

echo "getting vault passwords"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
source pipeline/variables.sh

echo "Testing docker on nodes"
./scripts/check-docker.sh service_cluster infra.json
echo "generating rke config"
./scripts/gen-rke-conf-sc.sh infra.json > ./eck-sc.yaml
echo "running RKE"
rke up --config ./eck-sc.yaml > "${GITHUB_WORKSPACE}/rke-sc-output"
export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
echo "running tests"
./pipeline/test/k8s/check-nodes.sh service_cluster infra.json

# Needed to upload it as an artifact to use in later jobs
chmod o+r kube_config_eck-sc.yaml

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"

echo "rke-sc completed!"