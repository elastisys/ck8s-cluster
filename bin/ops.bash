#!/bin/bash

# CK8S operator actions.

set -eu

here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

usage() {
    echo "Usage: kubectl <wc|sc> ..." >&2
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

case "${1}" in
    kubectl)
        shift
        ops_kubectl ${@}
    ;;
    *) usage ;;
esac
