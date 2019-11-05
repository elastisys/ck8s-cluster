SOURCE_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"

export TF_VAR_dns_prefix=${PREFIX}
export TF_VAR_ssh_pub_key_file_sc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${PREFIX}/ssh-keys/id_rsa_sc.pub
export TF_VAR_ssh_pub_key_file_wc=${SOURCE_PATH}/clusters/$CLOUD_PROVIDER/${PREFIX}/ssh-keys/id_rsa_wc.pub
