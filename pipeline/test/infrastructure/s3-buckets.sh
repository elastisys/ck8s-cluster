#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${S3COMMAND_CONFIG_FILE:?Missing S3COMMAND_CONFIG_FILE}"

buckets=("S3_HARBOR_BUCKET_NAME" "S3_VELERO_BUCKET_NAME" "S3_ES_BACKUP_BUCKET_NAME" "S3_INFLUX_BUCKET_NAME" "S3_SC_FLUENTD_BUCKET_NAME")

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
# S3 configuration is set in scripts/gen-s3cfg.sh script
S3_BUCKET_LIST=$(s3cmd --config=${S3COMMAND_CONFIG_FILE} ls)

for bucket in ${buckets[@]}
do
    check_if_bucket_exists $bucket
done