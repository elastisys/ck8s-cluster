export CK8S_VERSION="${CK8S_VERSION}"

export CLOUD_PROVIDER="${CK8S_CLOUD_PROVIDER}"
export ENVIRONMENT_NAME="${CK8S_ENVIRONMENT_NAME}"

# TODO: This needs a cleaner interface. We should try to make the CK8S setup
#       less dependent on domain name. Maybe make external access/ingress a
#       separate step?
export TF_VAR_dns_prefix="${CK8S_ENVIRONMENT_NAME}"
export ECK_BASE_DOMAIN=""
export ECK_OPS_DOMAIN=""
# If Exoscale:
# ECK_BASE_DOMAIN = ${CK8S_ENVIRONMENT_NAME}.a1ck.io
# ECK_OPS_DOMAIN = ops.${CK8S_ENVIRONMENT_NAME}.a1ck.io
# Else:
# ECK_OPS_DOMAIN = ops.${CK8S_ENVIRONMENT_NAME}.elastisys.se
# ECK_BASE_DOMAIN = ${CK8S_ENVIRONMENT_NAME}.elastisys.se

