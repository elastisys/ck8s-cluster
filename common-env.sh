SOURCE_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

export TF_VAR_dns_prefix=${ENVIRONMENT_NAME}
export TF_VAR_ssh_pub_key_file_sc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_sc.pub
export TF_VAR_ssh_pub_key_file_wc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${ENVIRONMENT_NAME}/ssh-keys/id_rsa_wc.pub

#
# Service settings
#

# Influx cronjob backup variables.
export INFLUX_ADDR=influxdb.influxdb-prometheus.svc:8088
export INFLUX_BACKUP_SCHEDULE="0 0 * * *"
