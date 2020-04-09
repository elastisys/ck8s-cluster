#!/bin/bash

# CK8S operator actions.

set -eu

here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

usage() {
    echo "Usage: kubectl <wc|sc> ..." >&2
    echo "       helmfile <wc|sc> ..." >&2
    exit 1
}

# Run arbitrary kubectl commands as cluster admin.
ops_kubectl() {
    case "${1}" in
        sc) kubeconfig="${secrets[kube_config_sc]}" ;;
        wc) kubeconfig="${secrets[kube_config_wc]}" ;;
        *) usage ;;
    esac
    shift
    with_kubeconfig "${kubeconfig}" kubectl ${@}
}

# Run arbitrary Helmfile commands as cluster admin.
ops_helmfile() {
    config_load

    case "${1}" in
        sc)
            cluster="service_cluster"
            kubeconfig="${secrets[kube_config_sc]}"
        ;;
        wc)
            cluster="workload_cluster"
            kubeconfig="${secrets[kube_config_wc]}"

            export CUSTOMER_NAMESPACES_COMMASEPARATED=$(echo "${CUSTOMER_NAMESPACES}" | tr ' ' ,)
            export CUSTOMER_ADMIN_USERS_COMMASEPARATED=$(echo "${CUSTOMER_ADMIN_USERS}" | tr ' ' ,)
        ;;
        *) usage ;;
    esac

    shift

    export CONFIG_PATH="${CK8S_CONFIG_PATH}"

    # TODO: Get rid of this.
    source "${scripts_path}/post-infra-common.sh" \
        "${config[infrastructure_file]}"

    source "${scripts_path}/set-storage-class.sh"

    # TODO: Delete this when Helm 3 is in place.
    sops_decrypt "${certs_path}/${cluster}/kube-system/certs/helm-key.pem"

    with_kubeconfig "${kubeconfig}" \
        helmfile -f "${here}/../helmfile/helmfile.yaml" -e ${cluster} ${@}
}

case "${1}" in
    kubectl)
        shift
        ops_kubectl ${@}
    ;;
    helmfile)
        shift
        ops_helmfile ${@}
    ;;
    *) usage ;;
esac
