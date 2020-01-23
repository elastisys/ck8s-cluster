
if [[ "$#" -lt 1 ]]
then
  >&2 echo "Usage: source post-infra-common.sh path-to-infra-file "
  return 1
fi

infra="$1"


# Cloud provider
: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

# Common environment variables needed for deploy-*.sh
if [ $CLOUD_PROVIDER == "exoscale" ]
then
    export NFS_SC_SERVER_IP=$(cat $infra | jq -r '.service_cluster.nfs_ip_addresses')
    export NFS_WC_SERVER_IP=$(cat $infra | jq -r '.workload_cluster.nfs_ip_addresses')
fi

export MASTER_WC_SERVER_IP=$(cat $infra | jq -r 'first(.workload_cluster.master_ip_addresses[].public_ip)')

# Domains
: "${ECK_OPS_DOMAIN:?Missing ECK_OPS_DOMAIN}"
: "${ECK_BASE_DOMAIN:?Missing ECK_BASE_DOMAIN}"

# Cert type
: "${CERT_TYPE:?Missing CERT_TYPE}"

# Export whether to skip tls verify or not.
if [[ "$CERT_TYPE" == "prod" ]];
then export TLS_VERIFY="true"
    export TLS_SKIP_VERIFY="false"
elif [[ "$CERT_TYPE" == "staging" ]];
then export TLS_VERIFY="false"
    export TLS_SKIP_VERIFY="true"
else
    echo "CERT_TYPE should be set to either 'prod' or 'staging'"
fi
