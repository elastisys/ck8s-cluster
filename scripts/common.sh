# Common environment variables needed for deploy-*.sh

# Domains
: "${ECK_SYSTEM_DOMAIN:?Missing ECK_SYSTEM_DOMAIN}"
: "${ECK_CUSTOMER_DOMAIN:?Missing ECK_CUSTOMER_DOMAIN}"

# Cert type
: "${CERT_TYPE:?Missing CERT_TYPE}"

# Kubeconfig
: "${KUBECONFIG:?Missing KUBECONFIG}"

# Export whether to skip tls verify or not.
if [[ "$CERT_TYPE" == "prod" ]];
then export TLS_VERIFY="true"
    export TLS_SKIP_VERIFY="false"
elif [[ "$CERT_TYPE" == "staging" ]];
then export TLS_VERIFY="false"
    export TLS_SKIP_VERIFY="true"
else 
    echo "CERT_TYPE should be set to either 'prod' or 'staging'"
    exit 1
fi