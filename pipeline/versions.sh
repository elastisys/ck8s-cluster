#!/bin/bash

set -eu -o pipefail

export here="$(dirname "$(readlink -f "$0")")"

source "${here}/common.bash"

file=${here}/../release/version.json
tmp=$(mktemp)
jq '.services = {}' "$file" > "$tmp" && mv "$tmp" "$file"

sops exec-file --no-fifo "${CK8S_CONFIG_PATH}/.state/kube_config_wc.yaml" \
    'KUBECONFIG={} ${here}/../release/get-versions.sh'

sops exec-file --no-fifo "${CK8S_CONFIG_PATH}/.state/kube_config_sc.yaml" \
    'KUBECONFIG={} ${here}/../release/get-versions.sh'

cat ${here}/../release/version.json > "${GITHUB_WORKSPACE}/version.json"
