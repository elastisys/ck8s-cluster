#!/bin/bash

set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${S3COMMAND_CONFIG_FILE:?Missing S3COMMAND_CONFIG_FILE}"
: "${S3_REGION_ADDRESS:?Missing S3_REGION_ADDRESS}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"

if [ $CLOUD_PROVIDER == "exoscale" ]
then
    host_bucket="%(bucket)s.$S3_REGION_ADDRESS"
elif [ $CLOUD_PROVIDER == "safespring" ] || [ $CLOUD_PROVIDER == "citycloud" ]
then
    host_bucket="$S3_REGION_ADDRESS"
else
    echo "Error: Only exoscale and safespring is supported as cloud providers in this script"
    exit 1
fi

cat <<EOF > ${S3COMMAND_CONFIG_FILE}
[default]
host_base = $S3_REGION_ADDRESS
host_bucket = $host_bucket
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
use_https = True
EOF