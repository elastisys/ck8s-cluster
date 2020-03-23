: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"

# Make CK8S_CONFIG_PATH absolute
export CK8S_CONFIG_PATH=$(readlink -f "${CK8S_CONFIG_PATH}")

# This is the home folder when the container is built but not when it is
# executed in GitHub actions
export HELM_HOME=/root/.helm

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
        log "~/.terraformrc already exists. Skipping."
    else
        echo 'credentials "app.terraform.io" {
          token = "'"${TF_TOKEN}"'"
        }' > ~/.terraformrc
    fi
}
