set -e

echo "sourcing variables"
export CLOUD_PROVIDER=exoscale
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source pipeline/init-exoscale.sh
source pipeline/init-ssh.sh
export TF_VAR_dns_prefix="pipeline-$GITHUB_RUN_ID"

echo "getting vault passwords"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
source pipeline/variables.sh

echo "testing docker"
./scripts/check-docker.sh workload_cluster infra.json
echo "generating rke config"
./scripts/gen-rke-conf-wc.sh infra.json > ./eck-wc.yaml
echo "running RKE"
rke up --config ./eck-wc.yaml > "${GITHUB_WORKSPACE}/rke-wc-output"
export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
echo "running tests"
./pipeline/test/k8s/check-nodes.sh workload_cluster infra.json

# Needed to upload it as an artifact to use in later jobs
chmod o+r kube_config_eck-wc.yaml

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
echo "rke-sc completed!"