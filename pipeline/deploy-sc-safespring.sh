set -e

echo "Sourcing variables"
export CLOUD_PROVIDER=safespring
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"

echo "Initializing vault usage"
source pipeline/vault-variables.sh
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
source pipeline/variables-safespring.sh

source ./scripts/post-infra-common.sh infra.json
export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml

echo "running deploy-sc.sh" 
./scripts/deploy-sc.sh > "${GITHUB_WORKSPACE}/deploy-sc-output"
kubectl get pods --all-namespaces
kubectl get nodes

cd ${CONFIG_PATH}
echo "Storing files in vault"

FILES="certs/service_cluster/kube-system/certs/*"
for file in ${FILES}
do
    echo "Trying to store file $file"
    cat ${file} | base64 | vault kv put eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file} base64-content=-
    if [ $? == 0 ]
    then echo "Success"
    fi
done

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
echo "Deploy sc completed!"