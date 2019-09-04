SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
pushd "${SCRIPTS_PATH}/../terraform/" > /dev/null
tf_out=$(terraform output -json)
export ECK_C_DOMAIN=$(echo ${tf_out} | jq -r '.c_dns_name.value' | sed 's/[^.]*[.]//')
export ECK_SS_DOMAIN=$(echo ${tf_out} | jq -r '.ss_dns_name.value' | sed 's/[^.]*[.]//')
: "${ECK_SS_DOMAIN:?Missing ECK_SS_DOMAIN}"
: "${ECK_C_DOMAIN:?Missing ECK_C_DOMAIN}"
popd > /dev/null