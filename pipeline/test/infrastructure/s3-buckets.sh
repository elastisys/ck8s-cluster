#!/bin/bash

set -eu -o pipefail

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

CK8S_CONFIG_FILE="${CK8S_CONFIG_PATH}/config.yaml"
CLOUD_PROVIDER="$(yq r ${CK8S_CONFIG_FILE} 'cloud_provider')"

if [ ! -f ${CK8S_CONFIG_FILE} ]; then
    echo "Missing bucket name" 1>&2
    exit
fi

buckets=(
    "s3_es_backup_bucket_name"
    "s3_harbor_bucket_name"
    "s3_influx_bucket_name"
    "s3_sc_fluentd_bucket_name"
    "s3_velero_bucket_name"
)

function get_bucket_name() {
    echo "$(yq r ${CK8S_CONFIG_FILE} \"$1\")"
}

# check if all the environment variables with S3 backet names are set
for bucket in ${buckets[@]}
do
    if [ -z "$(get_bucket_name $bucket)" ]; then
        echo "Missing bucket name" 1>&2
        exit
    fi
done

function check_if_bucket_exists() { # arguments: bucket key name
    local bucket_name=$(get_bucket_name $1)

    echo "Checking status of bucket ["${bucket_name}"] at [$CLOUD_PROVIDER]"
    BUCKET_EXISTS=$(echo "$S3_BUCKET_LIST" | awk "\$3~/^s3:\/\/${bucket_name}$/ {print \$3}")

    if [ $BUCKET_EXISTS ]; then
        echo "bucket [${bucket_name}] exists at [$CLOUD_PROVIDER]"
    else
        echo "bucket [${bucket_name}] does not exist at [$CLOUD_PROVIDER]"
        exit 1
    fi
}

# get a list of all the S3 buckets
S3_BUCKET_LIST=$(sops --config ${CK8S_CONFIG_PATH}/.sops.yaml \
                 exec-file ${CK8S_CONFIG_PATH}/.state/s3cfg.ini \
                 's3cmd --config={} ls')

echo "==============================="
echo "Testing S3 buckets"
echo "==============================="

for bucket in ${buckets[@]}
do
    check_if_bucket_exists $bucket
done
