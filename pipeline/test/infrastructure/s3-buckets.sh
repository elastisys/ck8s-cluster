#!/bin/bash

set -eu -o pipefail

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

source "${CK8S_CONFIG_PATH}/config.sh"

buckets=(
    "S3_ES_BACKUP_BUCKET_NAME"
    "S3_HARBOR_BUCKET_NAME"
    "S3_INFLUX_BUCKET_NAME"
    "S3_SC_FLUENTD_BUCKET_NAME"
    "S3_VELERO_BUCKET_NAME"
)

# check if all the environment variables with S3 backet names are set
for bucket in ${buckets[@]}
do
    : "${!bucket:?Missing $bucket}"
done

function check_if_bucket_exists() { # arguments: bucket name
    local bucket_name="$1"

    echo "Checking status of bucket ["${!bucket_name}"] at [$CLOUD_PROVIDER]"
    BUCKET_EXISTS=$(echo "$S3_BUCKET_LIST" | awk "\$3~/^s3:\/\/${!bucket_name}$/ {print \$3}")

    if [ $BUCKET_EXISTS ]; then
        echo "bucket [${!bucket_name}] exists at [$CLOUD_PROVIDER]"
    else
        echo "bucket [${!bucket_name}] does not exist at [$CLOUD_PROVIDER]"
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
