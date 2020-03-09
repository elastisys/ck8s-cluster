#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${S3COMMAND_CONFIG_FILE:?Missing S3COMMAND_CONFIG_FILE}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"
if [ $CLOUD_PROVIDER != "aws" ]
then
: "${S3_REGION_ADDRESS:?Missing S3_REGION_ADDRESS}"
else
: "${S3_REGION:?Missing S3_REGION}"
fi

case $CLOUD_PROVIDER in
    exoscale)
        host_bucket="%(bucket)s.$S3_REGION_ADDRESS"
        ;;
    safespring | citycloud)
        host_bucket="$S3_REGION_ADDRESS"
        ;;
    aws)
        ;;
    *)
        echo "Error: Unsupported cloud provider: ${CLOUD_PROVIDER}"
        exit 1
        ;;
esac

if [ $CLOUD_PROVIDER == "aws" ]
then
    cat <<EOF > ${S3COMMAND_CONFIG_FILE}
[default]
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
use_https = True
bucket_location = $S3_REGION
EOF
else
    cat <<EOF > ${S3COMMAND_CONFIG_FILE}
[default]
host_base = $S3_REGION_ADDRESS
host_bucket = $host_bucket
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
use_https = True
EOF
fi
