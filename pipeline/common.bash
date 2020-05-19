: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

# Make CK8S_CONFIG_PATH absolute
export CK8S_CONFIG_PATH=$(readlink -f "${CK8S_CONFIG_PATH}")

# We need to use this variable to override the default data path for helm
# TODO Change when this is closed https://github.com/helm/helm/issues/7919
export XDG_DATA_HOME="/root/.config"

export TF_IN_AUTOMATION="true"

# Import PGP key and preset passphrase
sops_pgp_setup() {
    # Not supplying PGP_KEY or PGP_PASSPHRASE assumes interactive run.
    if [ -z ${PGP_KEY+x} ] || [ -z ${PGP_PASSPHRASE+x} ]; then
        echo "PGP_KEY or PGP_PASSPHRASE not set." >&2
        echo "Assuming interactive run and key already in keyring." >&2
        return
    fi

    echo "${PGP_PASSPHRASE}" | \
        gpg --pinentry-mode loopback --passphrase-fd 0 --import \
        <(echo "${PGP_KEY}")

    echo allow-preset-passphrase > ~/.gnupg/gpg-agent.conf
    gpg-connect-agent reloadagent /bye

    keys=$(gpg --list-keys --with-colons --with-keygrip)
    keygrip=$(echo "${keys}" | awk -F: '$1 == "grp" {print $10;}')

    echo "${PGP_PASSPHRASE}" | \
        /usr/lib/gnupg2/gpg-preset-passphrase --preset "${keygrip}"
}

terraform_setup() {
    if [ -f ~/.terraformrc ]; then
        echo "~/.terraformrc already exists. Skipping."
    else
        echo 'credentials "app.terraform.io" {
          token = "'"${TF_TOKEN}"'"
        }' > ~/.terraformrc
    fi
}

config_update() {
    sed -i 's/'"${1}"'=".*"/'"${1}"'="'"${2}"'"/g' \
        "${CK8S_CONFIG_PATH}/config.sh"
}

secrets_update() {
    secrets_env="${CK8S_CONFIG_PATH}/secrets.env"
    sops --config "${CK8S_CONFIG_PATH}/.sops.yaml" -d -i "${secrets_env}"
    sed -i 's/'"${1}"'=.*/'"${1}"'='"${2}"'/g' "${secrets_env}"
    sops --config "${CK8S_CONFIG_PATH}/.sops.yaml" -e -i "${secrets_env}"

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

    sed -i ':a;N;$!ba;s/'"${1}"' = \[[^]]*\]/'"${1}"' = \["'${2}'\/32"\]/g' \
      "${CK8S_CONFIG_PATH}/config.tfvars"
}
