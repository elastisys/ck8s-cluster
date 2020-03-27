#!/bin/bash

# This script takes care of applying the different parts of a ck8s environment.
# infra: The ck8s cloud infrastructure.
# k8s: The ck8s Kubernetes components.
# apps: The ck8s service applications.
# It's not to be executed on its own but rather via `ck8s apply`.

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

#
# INFRA
#

infra_s3_gen() {
    log_info "Generating S3 config"

    S3COMMAND_CONFIG_FILE=/dev/stdout "${scripts_path}/gen-s3cfg.sh" | \
        sops_encrypt_stdin ini "${secrets[s3cfg_file]}"
}

infra_s3_run() {
    log_info "Creating S3 buckets"

    with_s3cfg "${secrets[s3cfg_file]}" \
        "${scripts_path}/manage-s3-buckets.sh" --create
}

infra_tf_run() {
    log_info "Applying Terraform config"

    pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
    echo '1' | TF_WORKSPACE="${ENVIRONMENT_NAME}" terraform init
    terraform workspace select "${ENVIRONMENT_NAME}"
    terraform apply \
        -var-file="${config[tfvars_file]}" \
        -var ssh_pub_key_sc="${config[ssh_pub_key_sc]}" \
        -var ssh_pub_key_wc="${config[ssh_pub_key_wc]}"
    popd > /dev/null

    "${scripts_path}/gen-infra.sh" > "${config[infrastructure_file]}"
}

infra_validate_ssh() {
    log_info "Validating SSH access"

    (
        with_ssh_agent "${secrets[ssh_priv_key_sc]}" \
            "${pipeline_path}/test/infrastructure/ssh.sh" service_cluster \
                "${config[infrastructure_file]}"
    )

    (
        with_ssh_agent "${secrets[ssh_priv_key_wc]}" \
            "${pipeline_path}/test/infrastructure/ssh.sh" workload_cluster \
                "${config[infrastructure_file]}"
    )
}

infra_ansible_run() {
    if [ "${CLOUD_PROVIDER}" = "safespring" ] || \
       [ "${CLOUD_PROVIDER}" = "citycloud" ]; then
        log_info "Running Ansible script to prepare hosts e.g. install Docker"

        "${scripts_path}/generate-inventory.sh" \
            "${config[infrastructure_file]}" > "${config[ansible_hosts]}"

        (
            with_ssh_agent "${secrets[ssh_priv_key_sc]}" \
                ansible-playbook -i "${config[ansible_hosts]}" --limit 'sc_*' \
                    "${ansible_path}/playbook.yml"
        )

        (
            with_ssh_agent "${secrets[ssh_priv_key_wc]}" \
                ansible-playbook -i "${config[ansible_hosts]}" --limit 'wc_*' \
                    "${ansible_path}/playbook.yml"
        )
    fi
}

infra_validate() {
    log_info "Validating S3 buckets"

    with_s3cfg "${secrets[s3cfg_file]}" \
        "${pipeline_path}/test/infrastructure/s3-buckets.sh"
}

infra() {
    log_info "Applying infrastructure"

    mkdir -p "${state_path}"

    infra_s3_gen
    infra_s3_run
    infra_tf_run
    infra_validate_ssh
    infra_ansible_run
    infra_validate

    log_info "Infrastructure applied successfully!"
}

#
# K8S
#

k8s_init() {
    log_info "Generating rke configs"

    "${scripts_path}/gen-rke-conf-sc.sh" "${config[infrastructure_file]}" | \
        sops_encrypt_stdin yaml "${secrets[rke_config_sc]}"
    "${scripts_path}/gen-rke-conf-wc.sh" "${config[infrastructure_file]}" | \
        sops_encrypt_stdin yaml "${secrets[rke_config_wc]}"
}

k8s_run_rke() {
    rke_config="${1}"
    rkestate="${2}"
    kube_config="${3}"
    ssh_key="${4}"

    # The rkestate file does not exist on the first run, to be able to decrypt
    # it we need to have something to encrypt. Yea, I know, it's ugly. :(
    if [ ! -f "${rkestate}" ]; then
        touch "${rkestate}"
        sops_encrypt "${rkestate}"
    fi

    (
        # We unfortunately can't use `sops exec-file` since rke does not allow
        # you to specify where to store the rkestate and kubeconfig file.
        # See: https://github.com/rancher/rke/issues/1040
        sops_decrypt "${rke_config}"
        sops_decrypt "${rkestate}"

        with_ssh_agent "${ssh_key}" rke up --config "${rke_config}"
    )

    sops_encrypt "${kube_config}"
}

k8s_run() {
    log_info "Running rke up for service cluster"

    k8s_run_rke "${secrets[rke_config_sc]}" "${secrets[rkestate_sc]}" \
                "${secrets[kube_config_sc]}" "${secrets[ssh_priv_key_sc]}"

    log_info "Running rke up for workload cluster"

    k8s_run_rke "${secrets[rke_config_wc]}" "${secrets[rkestate_wc]}" \
                "${secrets[kube_config_wc]}" "${secrets[ssh_priv_key_wc]}"

}

k8s_validate() {
    log_info "Validating Kubernetes nodes"

    with_kubeconfig "${secrets[kube_config_sc]}" \
        "${pipeline_path}/test/k8s/check-nodes.sh" service_cluster \
            "${config[infrastructure_file]}"

    with_kubeconfig "${secrets[kube_config_wc]}" \
        "${pipeline_path}/test/k8s/check-nodes.sh" workload_cluster \
            "${config[infrastructure_file]}"
}

k8s() {
    log_info "Applying Kubernetes"

    mkdir -p "${state_path}"

    k8s_init
    k8s_run
    k8s_validate

    log_info "Kubernetes applied successfully!"
}

#
# APPS
#

apps_init() {
    # TODO: We should try to get rid of the post-infra-common script.

    log_info "Running post infra script"
    source "${scripts_path}/post-infra-common.sh" \
        "${config[infrastructure_file]}"
}

apps_run() {
    log_info "Applying applications in service cluster"

    (
        # TODO: Remove when Helm 3 is in place
        certs="${certs_path}/service_cluster/kube-system/certs"
        sops_decrypt "${certs}/ca-key.pem"
        sops_decrypt "${certs}/helm-key.pem"
        sops_decrypt "${certs}/tiller-key.pem"

        with_kubeconfig "${secrets[kube_config_sc]}" \
            CONFIG_PATH="${CK8S_CONFIG_PATH}" "${scripts_path}/deploy-sc.sh"
    )

    log_info "Applying applications in workload cluster"

    (
        # TODO: Remove when Helm 3 is in place
        certs="${certs_path}/workload_cluster/kube-system/certs"
        sops_decrypt "${certs}/ca-key.pem"
        sops_decrypt "${certs}/helm-key.pem"
        sops_decrypt "${certs}/tiller-key.pem"

        with_kubeconfig "${secrets[kube_config_wc]}" \
            CONFIG_PATH="${CK8S_CONFIG_PATH}" "${scripts_path}/deploy-wc.sh"
    )
}

apps_validate() {
    log_info "Validating service cluster"

    with_kubeconfig "${secrets[kube_config_sc]}" \
        "${pipeline_path}/test/services/test-sc.sh"

    log_info "Validating workload cluster"

    with_kubeconfig "${secrets[kube_config_wc]}" \
        "${pipeline_path}/test/services/test-wc.sh"
}

apps() {
    log_info "Applying applications"

    apps_init
    apps_run
    apps_validate

    log_info "Applications applied successfully!"
}

#
# ENTRYPOINT
#

config_load

if [ "${1}" = "infra" ]; then
    infra
elif [ "${1}" = "k8s" ]; then
    k8s
elif [ "${1}" = "apps" ]; then
    apps
elif [ "${1}" = "all" ]; then
    infra
    k8s
    apps
else
    echo "ERROR: ${1} is not a valid argument"
    echo "Usage: ${0} <infra|k8s|apps|all>"
    exit 1
fi
