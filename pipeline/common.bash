: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

# Make CK8S_CONFIG_PATH absolute
export CK8S_CONFIG_PATH=$(readlink -f "${CK8S_CONFIG_PATH}")

get_my_ip() {
    curl ifconfig.me 2>/dev/null
}

whitelist_update() {
    #usage: whitelist_update variable-name ip-address
    #regex https://www.regextester.com/22
    if [[ $2 =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]; then
        echo "valid ip [$2]"
    else
        echo "Ip [$2] does not match ipv4 semantics"
        exit 1
    fi

    sed -i ':a;N;$!ba;s/\s*"'"${1}"'": \[[^]]*\]/"'"${1}"'": \["'${2}'\/32"\]/g' \
      "${CK8S_CONFIG_PATH}/tfvars.json"
}
