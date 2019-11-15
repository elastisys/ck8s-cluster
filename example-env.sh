export ENVIRONMENT_NAME=test
export CERT_TYPE="<staging|prod>"

#
# Infrastructure
#

export TF_VAR_sc_master_count=number # default 1
export TF_VAR_wc_master_count=number # default 1
export TF_VAR_sc_worker_count=number # default 1
export TF_VAR_wc_worker_count=number # default 1

# The AWS credentials are only needed if you don't have them in ~/.aws/credentials
export AWS_ACCESS_KEY_ID=12345abcde
export AWS_SECRET_ACCESS_KEY=somelongsecret

# S3 buckets
export S3_ACCESS_KEY=12345abcde
export S3_SECRET_KEY=somelongsecret
export S3_HARBOR_BUCKET_NAME=harbor-bucket-name
export S3_VELERO_BUCKET_NAME=velero-bucket-name
export S3_ES_BACKUP_BUCKET_NAME=es-backup-name
export S3_INFLUX_BUCKET_URL=s3://influxdb-bucket-name

# Note: You should just specify variables for ONE cloud provider!
# Comment out the rest or delete them.

#
# Exoscale
#

export CLOUD_PROVIDER=exoscale

# Machine sizes
export TF_VAR_sc_master_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_wc_master_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_sc_nfs_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_wc_nfs_size="<Small|Medium|Large|Extra-large>" # default "Small"
export TF_VAR_sc_worker_size="<Small|Medium|Large|Extra-large>" # default "Extra-large"
export TF_VAR_wc_worker_size="<Small|Medium|Large|Extra-large>" # default "Large"

export TF_VAR_exoscale_api_key=12345abcde
export TF_VAR_exoscale_secret_key=somelongsecret

#
# Safespring
#

export CLOUD_PROVIDER=safespring

export OS_USERNAME=user.name@elastisys.com
export OS_PASSWORD=somelongsecret

#
# Services
#

export ENABLE_HARBOR="<true|false>" # default true
export ENABLE_PSP="<true|false>" # default true
export ENABLE_OPA="<true|false>" # default true

# Identity providers
export AAA_CLIENT_ID=1234
export AAA_CLIENT_SECRET=somelongsecret
export GOOGLE_CLIENT_ID=1234512345abcdeabcde.apps.googleusercontent.com
export GOOGLE_CLIENT_SECRET=somelongsecret

# Only emails with these domains are allowed to login through dex.
# Applies to Google as identity provider and Grafana oauth login.
export OAUTH_ALLOWED_DOMAINS="example.com elastisys.com" # default "example.com"

# Customer access
export CUSTOMER_NAMESPACES="demo1 demo2 demo3" # default "demo"
export CUSTOMER_ADMIN_USERS="admin1@example.com admin2@example.com" # default "admin@example.com"

# Create a static dex user "admin@example.com"
export ENABLE_STATIC_DEX_LOGIN="<true|false>" # default false
# Dex static user password bcrypt hash (generate e.g. here https://bcrypt-generator.com/)
export DEX_STATIC_PWD="some-bcrypt-hash" # default hash of "password"

# Passwords for services
export GRAFANA_PWD=somelongsecret # default randomly generated
export HARBOR_PWD=somelongsecret # default randomly generated
export INFLUXDB_PWD=somelongsecret # default randomly generated

# Alerting variables
export ALERT_TO="slack" # default "slack", set to anything else to disable alerts
export SLACK_API_URL="https://..." # Default URL is for sending to the #ck8s-ops channel
