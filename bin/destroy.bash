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
        with_kubeconfig "${kube_config_sc}" \
            'kubectl delete ns elastic-system harbor monitoring fluentd influxdb-prometheus'
        with_kubeconfig "${kube_config_sc}" 'kubectl delete pv --all --wait'

        volumes_left="$(with_kubeconfig "${kube_config_sc}" \
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
    -var-file="${tfvars_file}" \
    -var ssh_pub_key_file_sc="${ssh_path}/id_rsa_sc.pub" \
    -var ssh_pub_key_file_wc="${ssh_path}/id_rsa_wc.pub"
popd > /dev/null

rm -f "${rkestate_sc}"
rm -f "${rkestate_wc}"
rm -f "${kube_config_sc}"
rm -f "${kube_config_wc}"

log_info "Aborting multipart uploads to S3 buckets"
with_s3cfg "${s3cfg_file}" "${scripts_path}/manage-s3-buckets.sh" --abort

log_info "Deleting S3 buckets"
with_s3cfg "${s3cfg_file}" "${scripts_path}/manage-s3-buckets.sh" --delete
