set -e
set -x

export CLOUD_PROVIDER=exoscale
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source pipeline/init-exoscale.sh
source pipeline/init-ssh.sh

# Export vault variables
source pipeline/vault-variables.sh

# Export vault token
export VAULT_TOKEN=$(./pipeline/vault-token-get.sh)

# Revoke vault token, remove password secrets for services
./pipeline/vault-cleanup.sh grafana harbor influxdb kubelogin_client dashboard_client grafana_client prometheus customer_prometheus customer_grafana customer_alertmanager elasticsearch-es-elastic-user

export TF_VAR_dns_prefix=pipeline-$GITHUB_RUN_ID
#Destroy infrastructure
cd terraform/exoscale
echo '1' | TF_WORKSPACE=pipeline terraform init
terraform workspace select pipeline-$GITHUB_RUN_ID
terraform destroy -auto-approve
terraform workspace select pipeline
terraform workspace delete pipeline-$GITHUB_RUN_ID