#!/bin/bash

set -e

: "${GITHUB_TOKEN:?Missing GITHUB_TOKEN}"
: "${EXOSCALE_API_KEY:?Missing EXOSCALE_API_KEY}"
: "${EXOSCALE_SECRET_KEY:?Missing EXOSCALE_SECRET_KEY}"

here="$(dirname "$(readlink -f "$0")")"
terraform_path="${here}/../terraform"

owner=elastisys
repo=ck8s

if [ "${#}" -ne 1 ]; then
    echo "Usage: destroy-pipeline.sh PIPELINE_ID" >&2
    exit 1
fi

pipeline_id="${1}"

api_url_root="https://api.github.com"
headers="Authorization: token ${GITHUB_TOKEN}"

github_api_url() {
    path="${1}"

    echo "${api_url_root}/repos/${owner}/${repo}/${path}"
}

github_api() {
    path="${1}"

    url=$(github_api_url ${path})

    echo "Calling ${url}" >&2

    response=$(curl -s -w "\n%{http_code}" -H "${headers}" "${url}")

    body=$(echo "${response}" | head -n-1)
    status_code=$(echo "${response}" | tail -n1)

    if [ "${status_code}" != "200" ]; then
        echo "ERROR: Status code ${status_code}" >&2
        echo "Response body:\n${body}" >&2
        exit 1
    fi

    echo "${body}"
}

github_api_download() {
    url="${1}"
    out="${2}"

    echo "Downloading ${url} to ${path}" >&2

    curl -fL -H "${headers}" -o "${out}" "${url}"
}

pipeline_response=$(github_api "actions/runs/${pipeline_id}/artifacts")
total_count=$(echo "${pipeline_response}" | jq -r .total_count)
if [ ${total_count} -ne 1 ]; then
    echo "ERROR: Expected total artifact count == 1" >&2
    exit 1
fi

archive_download_url=$(echo "${pipeline_response}" | \
                       jq -r .artifacts[0].archive_download_url)

tmpdir=$(mktemp -d /tmp/ck8s-pipeline-config-XXXXXXXXXX)
trap 'rm -rf ${tmpdir}' EXIT

config_zip_file="${tmpdir}/config.zip"
config_out="${tmpdir}/config"

github_api_download "${archive_download_url}" "${config_zip_file}"

unzip "${config_zip_file}" -d "${config_out}"

source "${config_out}/config.sh"

if [ "${CLOUD_PROVIDER}" != "exoscale" ]; then
    echo "ERROR: Only supports CLOUD_PROVIDER=exoscale" >&2
    exit 1
fi

pushd "${terraform_path}/${CLOUD_PROVIDER}" > /dev/null
echo '1' | TF_WORKSPACE="${ENVIRONMENT_NAME}" terraform init \
    -backend-config="${config_out}/backend_config.hcl"
TF_WORKSPACE="${ENVIRONMENT_NAME}" terraform destroy \
    -var-file="${config_out}/config.tfvars" \
    -var ssh_pub_key_sc="" \
    -var ssh_pub_key_wc="" \
    -var exoscale_api_key="${EXOSCALE_API_KEY}" \
    -var exoscale_secret_key="${EXOSCALE_SECRET_KEY}"

terraform workspace select pipeline
terraform workspace delete "${ENVIRONMENT_NAME}"
popd > /dev/null
