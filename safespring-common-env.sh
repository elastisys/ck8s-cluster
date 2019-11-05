export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://keystone.api.cloud.ipnett.se/v3
export OS_PROJECT_DOMAIN_NAME=elastisys.se
export OS_USER_DOMAIN_NAME=elastisys.se
export OS_PROJECT_NAME=infra.elastisys.se
export OS_REGION_NAME=se-east-1
export OS_PROJECT_ID=9f91e56185fb4f929c36430ac4bcbe6e
export S3_REGION=sto1
export S3_REGION_ENDPOINT=https://s3.sto1.safedc.net

# Override values from common-env.sh
export S3_HARBOR_BUCKET_NAME=harbor
export S3_VELERO_BUCKET_NAME=velero
export S3_INFLUX_BUCKET_URL=s3://influxdb-backup
