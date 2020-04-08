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

    log_info "Generating ansible inventories"
    pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
    terraform output ansible_inventory_sc > "${config[ansible_hosts_sc]}"
    terraform output ansible_inventory_wc > "${config[ansible_hosts_wc]}"
    popd > /dev/null
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
        log_info "Running Ansible script for loadbalancers and extra volumes"

        (
            with_ssh_agent "${secrets[ssh_priv_key_sc]}" \
                ansible-playbook -i "${config[ansible_hosts_sc]}" \
                    "${ansible_path}/infrastructure.yml"
        )

        (
            with_ssh_agent "${secrets[ssh_priv_key_wc]}" \
                ansible-playbook -i "${config[ansible_hosts_wc]}" \
                    "${ansible_path}/infrastructure.yml"
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

k8s_run_kubeadm() {
    ansible_inventory="${1}"
    kube_config="${2}"
    ssh_key="${3}"

    (
        with_ssh_agent "${ssh_key}" \
            ansible-playbook -i "${ansible_inventory}" \
                --extra-vars=kubeconfig_path="${kube_config}" \
                "${ansible_path}/deploy-kubernetes.yml"
    )

    sops_encrypt "${kube_config}"
}

k8s_run() {
    log_info "Initializing/configuring Kubernetes for service cluster"

    k8s_run_kubeadm "${config[ansible_hosts_sc]}" "${secrets[kube_config_sc]}" \
                "${secrets[ssh_priv_key_sc]}"

    log_info "Initializing/configuring Kubernetes for workload cluster"

    k8s_run_kubeadm "${config[ansible_hosts_wc]}" "${secrets[kube_config_wc]}" \
                "${secrets[ssh_priv_key_wc]}"
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

    k8s_run
    k8s_validate

    log_info "Kubernetes applied successfully!"
}

#
# APPS
#

apps_init() {
    # Get helm major version
    helm_version=$(helm version -c --short | tr -d 'Client: v' | head -c 1)
    if [ "${helm_version}" != "3" ]; then
        log_error "Only helm 3 is supported"
        exit 1
    fi

    # TODO: We should try to get rid of the post-infra-common script.

    log_info "Running post infra script"
    source "${scripts_path}/post-infra-common.sh" \
        "${config[infrastructure_file]}"
}

apps_run() {
    log_info "Applying applications in service cluster"

    (
        with_kubeconfig "${secrets[kube_config_sc]}" \
            CONFIG_PATH="${CK8S_CONFIG_PATH}" "${scripts_path}/deploy-sc.sh"
    )

    log_info "Applying applications in workload cluster"

    (
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
