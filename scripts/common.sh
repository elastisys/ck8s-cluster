SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
cd ${SCRIPTS_PATH}/../terraform
tf_out=$(terraform output -json)
export ECK_C_DOMAIN=$(echo ${tf_out} | jq -r '.c_dns_name.value' | sed 's/[^.]*[.]//')
export ECK_SS_DOMAIN=$(echo ${tf_out} | jq -r '.ss_dns_name.value' | sed 's/[^.]*[.]//')
: "${ECK_SS_DOMAIN:?Missing ECK_SS_DOMAIN}"
: "${ECK_C_DOMAIN:?Missing ECK_C_DOMAIN}"
cd ${SCRIPTS_PATH}
