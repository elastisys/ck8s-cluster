set -e
echo "Sourcing variables"
export CLOUD_PROVIDER=exoscale
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source pipeline/init-exoscale.sh
source pipeline/init-ssh.sh
export TF_VAR_dns_prefix="pipeline-$GITHUB_RUN_ID"
#Export vault variables
echo "Initializing vault usage"
source pipeline/vault-variables.sh
#Export vault token and save it to disk
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)
#Generate and store passwords
source scripts/get-gen-secrets.sh > /dev/null
#Infrastructure
echo -e "\nTerraform"
cd terraform/exoscale
echo "Init terraform"
echo '1' | TF_WORKSPACE=pipeline terraform init
echo "Creating new terraform workspace"
terraform workspace new pipeline-$GITHUB_RUN_ID
echo "Initializing workspace"
terraform init
echo "Setting local executiong mode"
./set-execution-mode.sh
echo "Running terraform plan"
terraform plan -var 'public_ingress_cidr_whitelist=["0.0.0.0/0"]' -out=tfplan -input=false > "${GITHUB_WORKSPACE}/tfoutput"
echo "Running terraform apply"
terraform apply -input=false tfplan >> "${GITHUB_WORKSPACE}/tfoutput"
echo "Terraform successful"
#Generate infra.json
cd ../..
echo -e "\nGenerating infra.json"
./scripts/gen-infra.sh > "${GITHUB_WORKSPACE}/infra.json"
echo -e "\nTesting infrastructure"
./pipeline/test/infrastructure/ssh.sh service_cluster infra.json
./pipeline/test/infrastructure/ssh.sh workload_cluster infra.json

# Revoke vault token.
curl --header "X-Vault-Token: $VAULT_TOKEN" --request POST "${VAULT_ADDR}/v1/auth/token/revoke-self"
echo -e "\nInfrastructure created and tested successfully"