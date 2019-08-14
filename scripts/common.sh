
: "${ECK_SS_DOMAIN:?Missing ECK_SS_DOMAIN}"
: "${ECK_C_DOMAIN:?Missing ECK_C_DOMAIN}"
: "${CERT_TYPE:?Missing CERT_TYPE}"

if [[ "$CERT_TYPE" == "prod" ]];
then export TLS_VERIFY="true"
    export TLS_SKIP_VERIFY="false"
elif [[ "$CERT_TYPE" == "staging" ]];
then export TLS_VERIFY="false"
    export TLS_SKIP_VERIFY="true"
else echo "CERT_TYPE should be set to prod or staging"; exit 1;
fi
