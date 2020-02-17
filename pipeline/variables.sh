#!/bin/bash

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
export ECK_BASE_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name')
export ECK_OPS_DOMAIN=$(cat infra.json | jq -r '.service_cluster.domain_name' | sed 's/^/ops./')
export CERT_TYPE=staging

source common-env.sh

if [[ "$CLOUD_PROVIDER" = "exoscale" ]]
then
    export S3_REGION=ch-gva-2
    export S3_REGION_ADDRESS=sos-ch-gva-2.exo.io
elif [[ "$CLOUD_PROVIDER" = "safespring" ]]
then
    export S3_REGION=sto1
    export S3_REGION_ADDRESS=s3.sto1.safedc.net
fi

export S3COMMAND_CONFIG_FILE=~/.s3cfg
export S3_REGION_ENDPOINT=https://${S3_REGION_ADDRESS}
export S3_HARBOR_BUCKET_NAME=${GITHUB_RUN_ID}-harbor-pipeline
export S3_VELERO_BUCKET_NAME=${GITHUB_RUN_ID}-velero-pipeline
export S3_ES_BACKUP_BUCKET_NAME=${GITHUB_RUN_ID}-elasticsearch-pipeline
export S3_INFLUX_BUCKET_NAME=${GITHUB_RUN_ID}-influxdb-pipeline
export S3_SC_FLUENTD_BUCKET_NAME=${GITHUB_RUN_ID}-sc-logs-pipeline

# Disable alerts
export ALERT_TO=null
# In case we want alerts at some point
export SLACK_API_URL=https://hooks.slack.com/services/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

export OAUTH_ALLOWED_DOMAINS="example.com"

# Customer access
export CUSTOMER_NAMESPACES="demo1 demo2 demo3"
export CUSTOMER_ADMIN_USERS="admin1@example.com admin2@example.com"

#This is the home folder when the container is built, but not when it is executed in github actions
export HELM_HOME=/root/.helm
