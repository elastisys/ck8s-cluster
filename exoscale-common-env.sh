# For harbor image chart storage and velero backup storage
export S3_REGION=ch-gva-2
export S3_REGION_ADDRESS=sos-ch-gva-2.exo.io
export S3_REGION_ENDPOINT=https://$S3_REGION_ADDRESS

export ECK_BASE_DOMAIN=${ENVIRONMENT_NAME}.a1ck.io
export ECK_OPS_DOMAIN=ops.${ENVIRONMENT_NAME}.a1ck.io