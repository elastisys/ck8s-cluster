: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

# Make CK8S_CONFIG_PATH absolute
export CK8S_CONFIG_PATH=$(readlink -f "${CK8S_CONFIG_PATH}")

# This is the home folder when the container is built but not when it is
# executed in GitHub actions
export HELM_HOME=/root/.helm

export TF_IN_AUTOMATION="true"

# Import PGP key, export SOPS_PGP_FP and preset passphrase
sops_pgp_setup() {
    if [ -z ${PGP_KEY+x} ] || [ -z ${PGP_PASSPHRASE+x} ]; then
        if [ -z ${SOPS_PGP_FP+x} ]; then
            echo "SOPS_PGP_FP required if PGP_KEY or PGP_PASSPHRASE unset." >&2
            exit 1
        fi
        echo "PGP_KEY or PGP_PASSPHRASE not set. Assuming key in keyring." >&2
        return
    fi

    echo "${PGP_PASSPHRASE}" | \
        gpg --pinentry-mode loopback --passphrase-fd 0 --import \
        <(echo "${PGP_KEY}")

    echo allow-preset-passphrase > ~/.gnupg/gpg-agent.conf
    gpg-connect-agent reloadagent /bye

    keys=$(gpg --list-keys --with-colons --with-keygrip)
    keygrip=$(echo "${keys}" | awk -F: '$1 == "grp" {print $10;}')
    export SOPS_PGP_FP=$(echo "${keys}" | awk -F: '$1 == "fpr" {print $10;}')

    echo "${PGP_PASSPHRASE}" | \
        /usr/lib/gnupg2/gpg-preset-passphrase --preset "${keygrip}"
}

terraform_setup() {
    if [ -f ~/.terraformrc ]; then
        log "~/.terraformrc already exists. Skipping."
    else
        echo 'credentials "app.terraform.io" {
          token = "'"${TF_TOKEN}"'"
        }' > ~/.terraformrc
    fi
}
