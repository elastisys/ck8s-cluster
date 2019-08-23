#!/bin/bash
# Sets remote execution of current workspace. Default to false. Set arg1 to true to enable
# Local execution.

set -e

: "${TF_TOKEN:?Missing TF_TOKEN}"

WORKSPACE=a1-demo-`terraform workspace show`
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
