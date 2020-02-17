set -e

: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"

source pipeline/variables.sh

echo -e "\nConfiguring s3cmd"
./scripts/gen-s3cfg.sh

echo -e "\nCreating S3 buckets"
./scripts/manage-s3-buckets.sh --create

echo -e "\nTesting S3 buckets"
./pipeline/test/infrastructure/s3-buckets.sh

echo -e "\nS3 buckets created and tested successfully"