#!/bin/bash

# OBS: DONT USE THIS IN PRODUCTION

# TODO: This is currently a very crude teardown flow. It needs to be expanded
#       upon with things like cleaning up loadbalancer, volumes etc.

# To run it, execute the following:
# sops exec-env [config-path/secrets.env] ./destroy.bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

config_load

delete_volumes() {
    kube_config=${1}

    # Get all namespaces with PVCs, sort and remove duplicates
    volume_namespaces="$(with_kubeconfig "${kube_config}" \
        'kubectl get pv -o jsonpath="{.items[*].spec.claimRef.namespace}" |
            tr " " "\n" | sort -u | tr "\n" " "
        ')"

    with_kubeconfig "${kube_config}" \
        "kubectl delete ns ${volume_namespaces}"
    with_kubeconfig "${kube_config}" \
        'kubectl delete pv --all --wait'

    volumes_left="$(with_kubeconfig "${kube_config}" \
        'kubectl get pv -o json |
            jq ".items[] | {
                pv_name: .metadata.name,
                pvc_namespace: .spec.claimRef.namespace,
                pvc_name: .spec.claimRef.name
            }"')"

    if [ "${volumes_left}" != "" ]; then
        log_warning "WARNING: There seems to be volumes left in the"
        log_warning "         cluster, this will result in volumes that"
        log_warning "         needs to be cleaned up manually."
        log_warning "Volumes left:"
        log_warning "${volumes_left}"
    else
        log_info "All volumes where successfully cleaned up!"
    fi
}

if [ "${CLOUD_PROVIDER}" = "safespring" ] || \
   [ "${CLOUD_PROVIDER}" = "citycloud" ]; then
    log_info "Cleaning up volumes"

    # TODO: We should find a way to make this general and in a way where PVs
    #       that does not have reclaim policy DELETE are not deleted. Right now
    #       this only cleans up all known volumes.
    #       One possible solution could be to iterate over all namespaces and
    #       delete PVCs instead.

    # We want to tear down the infrastructure even if volume cleanup fails.
    # This could happen, for example, when the kubeconfig file hasn't been
    # created yet due to some error during the Kubernetes deployment.
    set +e
    (
        set -e
        log_info "Deleting volumes in the service cluster"
        delete_volumes "${secrets[kube_config_sc]}"
        log_info "Deleting volumes in the workload cluster"
        delete_volumes "${secrets[kube_config_wc]}"
    )
    if [ "${?}" -ne 0 ]; then
        log_error \
            "ERROR: Volume cleanup failed. Manual cleanup might be required."
    fi
    set -e
fi

log_info "Destroying Terraform infrastructure"

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE="${ENVIRONMENT_NAME}" terraform init
terraform workspace select "${ENVIRONMENT_NAME}"
terraform destroy \
    -var-file="${config[tfvars_file]}" \
    -var ssh_pub_key_sc="${config[ssh_pub_key_sc]}" \
    -var ssh_pub_key_wc="${config[ssh_pub_key_wc]}"
popd > /dev/null

rm -f "${secrets[kube_config_sc]}"
rm -f "${secrets[kube_config_wc]}"
rm -f "${CK8S_CONFIG_PATH}/customer/kubeconfig.yaml"

log_info "Aborting multipart uploads to S3 buckets"
with_s3cfg "${secrets[s3cfg_file]}" \
    "${scripts_path}/manage-s3-buckets.sh" --abort

log_info "Deleting S3 buckets"
with_s3cfg "${secrets[s3cfg_file]}" \
    "${scripts_path}/manage-s3-buckets.sh" --delete
