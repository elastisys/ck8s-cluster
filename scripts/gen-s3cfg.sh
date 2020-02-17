#!/bin/bash

set -e

: "${S3COMMAND_CONFIG_FILE:?Missing S3COMMAND_CONFIG_FILE}"
: "${S3_REGION_ADDRESS:?Missing S3_REGION_ADDRESS}"
: "${S3_ACCESS_KEY:?Missing S3_ACCESS_KEY}"
: "${S3_SECRET_KEY:?Missing S3_SECRET_KEY}"

cat <<EOF > ${S3COMMAND_CONFIG_FILE}
[default]
host_base = $S3_REGION_ADDRESS
host_bucket = %(bucket)s.$S3_REGION_ADDRESS
access_key = $S3_ACCESS_KEY
secret_key = $S3_SECRET_KEY
use_https = True
EOF