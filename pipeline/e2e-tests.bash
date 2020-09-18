#!/bin/bash

set -eu -o pipefail

here="$(dirname "$(readlink -f "$0")")"
test_path="${here}/test"

source "${here}/common.bash"

# Test ssh and kubectl access

ckctl status --cluster sc
ckctl status --cluster wc

# Test S3 buckets

"${test_path}/infrastructure/s3-buckets.sh"

# Test whitelisting

"${test_path}/infrastructure/nodeport-whitelist.sh" startup

# TODO: Would be nice to replace this with something like:
#       ckctl whitelist [--ingress] [--kubernetes] CIDR
whitelist_update public_ingress_cidr_whitelist 127.0.0.1
whitelist_update api_server_whitelist 127.0.0.1
whitelist_update nodeport_whitelist 127.0.0.1
ckctl internal terraform apply --cluster sc
ckctl internal terraform apply --cluster wc

"${test_path}/infrastructure/nodeport-whitelist.sh" negative
"${test_path}/infrastructure/whitelist.sh" negative

my_ip=$(get_my_ip)
whitelist_update public_ingress_cidr_whitelist "${my_ip}"
whitelist_update api_server_whitelist "${my_ip}"
whitelist_update nodeport_whitelist "${my_ip}"
ckctl internal terraform apply --cluster sc
ckctl internal terraform apply --cluster wc

"${test_path}/infrastructure/nodeport-whitelist.sh" positive
"${test_path}/infrastructure/whitelist.sh" positive
"${test_path}/infrastructure/nodeport-whitelist.sh" cleanup

# Run smoke tests (simple deployment and LoadBalancer on supported cloud providers)
# We only run this on WC as SC is thoroughly tested from all apps deployed there.
"${test_path}/k8s/test-deploy.sh"
