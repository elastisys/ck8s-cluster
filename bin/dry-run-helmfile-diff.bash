#!/bin/bash

# This script is used to run helmfile diff against one of the clusters.
# It's not to be executed on it's own but rather via `ck8s dry-run`.

# TODO: This script is heavily based on the deploy-*.sh scripts and should be
#       cleaned up once things have been cleaned up.

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
source "${here}/common.bash"

export CONFIG_PATH="${CK8S_CONFIG_PATH}"

case $CLOUD_PROVIDER in

  safespring | citycloud)
    export STORAGE_CLASS=cinder-storage
    ;;

  exoscale)
    export STORAGE_CLASS=nfs-client
    ;;

  *)
    echo "ERROR: Unknown CLOUD_PROVIDER [$CLOUD_PROVIDER], STORAGE_CLASS value could not be set."
    exit 1
    ;;
esac

export CUSTOMER_NAMESPACES_COMMASEPARATED=$(echo "$CUSTOMER_NAMESPACES" | tr ' ' ,)
export CUSTOMER_ADMIN_USERS_COMMASEPARATED=$(echo "$CUSTOMER_ADMIN_USERS" | tr ' ' ,)

source "${scripts_path}/post-infra-common.sh" "${config[infrastructure_file]}"

cd "${here}/../helmfile"

certs="${certs_path}/${1}/kube-system/certs"
sops_decrypt "${certs}/ca-key.pem"
sops_decrypt "${certs}/helm-key.pem"
sops_decrypt "${certs}/tiller-key.pem"

helmfile -e ${1} -f helmfile.yaml diff
