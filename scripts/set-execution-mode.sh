#!/bin/bash
# Sets execution mode of current workspace. Default to false(local execution). Set arg1 to true to enable
# remote execution.
# When this issue is resolved then we can remove this script:
# https://github.com/hashicorp/terraform/issues/23261

set -e

: "${TF_TOKEN:?Missing TF_TOKEN}"
: "${CLOUD_PROVIDER:?Missing CLOUD_PROVIDER}"
: "${CK8S_ENVIRONMENT_NAME:?Missing CK8S_ENVIRONMENT_NAME}"

case $CLOUD_PROVIDER in
  exoscale)
    WORKSPACE=a1-demo-$CK8S_ENVIRONMENT_NAME
    ;;
  safespring)
    WORKSPACE=safespring-demo-$CK8S_ENVIRONMENT_NAME
    ;;
  citycloud)
    WORKSPACE=citycloud-$CK8S_ENVIRONMENT_NAME
    ;;
  aws)
    WORKSPACE=aws-$CK8S_ENVIRONMENT_NAME
    ;;
  *)
    echo "Error: Unsupported cloud provider: ${CLOUD_PROVIDER}"
    exit 1
    ;;
esac

RUN_REMOTE="false"

if [[ "$1" == "true" ]];then
  RUN_REMOTE=$1
fi
curl \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request PATCH \
  --data \
'{
  "data": {
    "attributes": {
      "name": "'$WORKSPACE'",
      "environment": "default",
      "operations": '$RUN_REMOTE',
      "terraform-version": "0.12.6",
      "file-triggers-enabled": true
    },
    "relationships": {
      "organization": {
        "data": {
          "type": "organizations",
          "id": "elastisys"
        }
      }
    },
    "type": "workspaces"
  }
}' https://app.terraform.io/api/v2/organizations/elastisys/workspaces/$WORKSPACE
echo -e "\n\nworkspace: $WORKSPACE remote execution is set to: $RUN_REMOTE"
