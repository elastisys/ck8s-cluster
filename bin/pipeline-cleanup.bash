#!/bin/bash

# This script is supposed to help with cleaning up failed pipelines.
# It will attempt to run `terraform destroy`, remove the workspace and delete
# the S3 buckets.

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

if [[ "$#" -lt 1 ]]
then
    >&2 echo 'Usage: sops exec-env ${CK8S_CONFIG_PATH}/secrets.env "pipeline-cleanup.bash <terraform-worspace>"'
    exit 1
fi

echo "This script will attempt to destroy any remaining resources in terraform"
echo "and delete the terraform workspace. It will also try to delete the S3"
echo "buckets. It will use your credentials from the CK8S_CONFIG_PATH in order"
echo "to do so."
echo
echo "Note that the script CANNOT remove volumes or load balancers created"
echo "dynamically in Kubernetes. You MUST remove these manually!"
echo "To do so, use either the cloud providers CLI or web GUI."
echo "If you find IP addresses, volumes, networks or similar that have names"
echo "related to your pipeline, they probably are and should be removed."
echo "Another thing to look for is detached volumes or unused IP addresses."
echo
echo "If you are having troubles deleting a pipeline, you may want to prevent"
echo "terraform from trying to refresh the state before deleting."
echo "This can be done by exporting the env var"
echo "TF_CLI_ARGS_destroy='-refresh=false'"
echo
echo -n "Press enter to continue"
read reply


config_load

workspace="${1}"

echo
echo "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo "Destroying terraform workspace ${workspace} using ${CK8S_CONFIG_PATH} as config path."
echo "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo -n "Do you want to continue (y/n): "
read reply
if [[ ${reply} != "y" ]]; then
    exit 1
fi

log_info "Destroying Terraform infrastructure"

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE="${workspace}" terraform init -backend-config="${config[backend_config]}"
TF_WORKSPACE="${workspace}" terraform destroy \
    -var-file="${config[tfvars_file]}" \
    -var ssh_pub_key_sc="${config[ssh_pub_key_sc]}" \
    -var ssh_pub_key_wc="${config[ssh_pub_key_wc]}"

# TODO: If above fails, try deleting one resource at a time with
# terraform destroy -target <some-target>
# and/or give the users instructions on how to do it.
# Also: Add steps for forcing the deletion of the workspace.

log_info "Deleting Terraform workspace"

# It is not possible to delete the workspace that is selected, so we use the
# pipeline workspace as a workaround.
terraform workspace select pipeline
terraform workspace delete "${workspace}"

popd > /dev/null


bucket_names="es-backup harbor influxdb sc-logs velero"

echo
echo "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo "Deleting S3 buckets with prefix \"${workspace}\" and suffixes in [${bucket_names}]."
echo "¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤"
echo -n "Do you want to continue (y/n): "
read reply
if [[ ${reply} != "y" ]]; then
    exit 1
fi

for bucket in ${bucket_names}
do
    with_s3cfg "${secrets[s3cfg_file]}" \
        "s3cmd --config {} rb s3://${workspace}-${bucket} --force --recursive"
done
