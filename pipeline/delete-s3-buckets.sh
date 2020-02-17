set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

source pipeline/variables.sh

echo -e "\nConfiguring s3cmd"
./scripts/gen-s3cfg.sh

echo -e "\nAborting multipart uploads to S3 buckets"
./scripts/manage-s3-buckets.sh --abort

echo -e "\nDeleting S3 buckets"
./scripts/manage-s3-buckets.sh --delete

echo "S3 buckets deleted!"