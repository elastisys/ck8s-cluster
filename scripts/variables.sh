SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
pushd "${SCRIPTS_PATH}/../" > /dev/null

export ECK_CUSTOMER_DOMAIN=$(cat hosts.json | jq -r '.customer_dns_name.value' | sed 's/[^.]*[.]//')
export ECK_SYSTEM_DOMAIN=$(cat hosts.json | jq -r '.system_services_dns_name.value' | sed 's/[^.]*[.]//')

popd > /dev/null

export S3_ACCESS_KEY=$EXOSCALE_API_KEY
export S3_SECRET_KEY=$EXOSCALE_SECRET_KEY
export S3_REGION=de-fra-1
export S3_REGION_ENDPOINT=https://sos-de-fra-1.exo.io
export S3_BUCKET_NAME=harbor-bucket