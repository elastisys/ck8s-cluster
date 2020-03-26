# This file is not supposed to be executed on it's own, but rather is sourced
# by the other scripts in this path. It holds common paths and functions that
# are used throughout all of the scripts.

: "${CK8S_CONFIG_PATH:?Missing CK8S_CONFIG_PATH}"
: "${SOPS_PGP_FP:?Missing SOPS_PGP_FP}"

# Make CK8S_CONFIG_PATH absolute
export CK8S_CONFIG_PATH=$(readlink -f "${CK8S_CONFIG_PATH}")

here="$(dirname "$(readlink -f "$BASH_SOURCE")")"
root_path="${here}/.."
config_defaults_path="${root_path}/config"
scripts_path="${root_path}/scripts"
terraform_path="${root_path}/terraform"
ansible_path="${root_path}/ansible"
pipeline_path="${root_path}/pipeline"
version_file="${root_path}/release/version.json"

config_file="${CK8S_CONFIG_PATH}/config.sh"
secrets_file="${CK8S_CONFIG_PATH}/secrets.env"
tfvars_file="${CK8S_CONFIG_PATH}/config.tfvars"
state_path="${CK8S_CONFIG_PATH}/.state"
# TODO: Put in state?
ssh_path="${CK8S_CONFIG_PATH}/ssh"

infrastructure_file="${state_path}/infra.json"
ansible_hosts="${state_path}/ansible_hosts.ini"

s3cfg_file="${state_path}/s3cfg.ini"

rke_config_sc="${state_path}/rke_sc.yaml"
rke_config_wc="${state_path}/rke_wc.yaml"

rkestate_sc="${state_path}/rke_sc.rkestate"
rkestate_wc="${state_path}/rke_wc.rkestate"

kube_config_sc="${state_path}/kube_config_rke_sc.yaml"
kube_config_wc="${state_path}/kube_config_rke_wc.yaml"

ssh_priv_key_sc="${ssh_path}/id_rsa_sc"
ssh_pub_key_sc="${ssh_priv_key_sc}.pub"

ssh_priv_key_wc="${ssh_path}/id_rsa_wc"
ssh_pub_key_wc="${ssh_priv_key_wc}.pub"

ssh_auth_sock="${ssh_path}/ssh_auth_sock"

# TODO: Remove when Helm 3 is in place
certs_path="${CK8S_CONFIG_PATH}/certs"

log_info() {
    echo -e "[\e[34mck8s\e[0m] ${@}" 1>&2
}

log_warning() {
    echo -e "[\e[33mck8s\e[0m] ${@}" 1>&2
}

log_error() {
    echo -e "[\e[31mck8s\e[0m] ${@}" 1>&2
}

version_get() {
    cat "${version_file}" | jq -r .ck8s
}

# Check if the config version matches the current CK8S version.
# TODO: Simple hack to make sure version matches, we need to have a proper way
#       of making sure that the version is supported in the future.
validate_version() {
    version=$(version_get)

    if [ "${version}" != "${CK8S_VERSION}" ]; then
        log_error "ERROR: Version mismatch!"
        log_error "Config version: ${CK8S_VERSION}"
        log_error "CK8S version: ${version}"
        exit 1
    fi
}

# Check if the cloud provider is supported.
validate_cloud() {
    if [ "${1}" != "exoscale" ] &&
       [ "${1}" != "safespring" ] &&
       [ "${1}" != "citycloud" ]; then
        log_error "ERROR: Unsupported cloud provider: ${1}"
        exit 1
    fi
}

# Make sure that all required configuration options are set in the config.
# TODO: Simple hack to make sure configuration is valid, we need to have a
#       proper way of making sure that the configuration is valid in the
#       future.
validate_config() {
    validate() {
        file="${1}"
        shift

        for opt in ${@}; do
            set +u
            if [ -z "${!opt}" ]; then
                log_error "ERROR: Missing ${opt} in ${CK8S_CONFIG_PATH}/${file}"
                exit 1
            fi
            set -u
        done
    }


    options=$(cat "${config_defaults_path}/config/head.sh" \
                  "${config_defaults_path}/config/${CLOUD_PROVIDER}.sh" \
                  "${config_defaults_path}/config/tail.sh" | \
                grep '^export' | sed 's/.*export \(.*\)=.*/\1/' | uniq)
    validate config.sh ${options}

    options=$(cat "${config_defaults_path}/secrets/secrets.env" \
                  "${config_defaults_path}/secrets/${CLOUD_PROVIDER}.env" \
                  | grep -v '^#' | sed 's/\(.*\)=.*/\1/' | uniq)
    validate secrets.env ${options}
}

# Load and validate all configuration options from the config path.
config_load() {
    source "${config_file}"

    validate_version
    validate_cloud "${CLOUD_PROVIDER}"
    validate_config
}

# Normally a signal handler can only run one command. Use this to be able to
# add multiple traps for a single signal.
append_trap() {
    cmd="${1}"
    signal="${2}"

    if [ "$(trap -p ${signal})" = "" ]; then
        trap "${cmd}" "${signal}"
        return
    fi

    previous_trap_cmd() { printf '%s\n' "$3"; }

    new_trap() {
        eval "previous_trap_cmd $(trap -p "${signal}")"
        printf '%s\n' "${cmd}"
    }

    trap "$(new_trap)" "${signal}"
}

# Encrypt stdin to file. If the file already exists it's overwritten.
sops_encrypt_stdin() {
    sops -e --input-type "${1}" --output-type "${1}" /dev/stdin > "${2}"
}

# Encrypt a file in place.
sops_encrypt() {
    # https://github.com/mozilla/sops/issues/460
    if fgrep -q 'sops:' "${1}" || \
        fgrep -q '"sops":' "${1}" || \
        fgrep -q '[sops]' "${1}" || \
        fgrep -q 'sops_version=' "${1}"; then
        log_info "Already encrypted ${1}"
        return
    fi

    log_info "Encrypting ${1}"

    sops -e -i "${1}"
}

# Check that a file exists and is actually encrypted using SOPS.
sops_decrypt_verify() {
    if [ ! -f "${1}" ]; then
        log_error "ERROR: Encrypted file not found: ${1}"
        exit 1
    fi

    # https://github.com/mozilla/sops/issues/460
    if ! fgrep -q 'sops:' "${1}" && \
       ! fgrep -q '"sops":' "${1}" && \
       ! fgrep -q '[sops]' "${1}" && \
       ! fgrep -q 'sops_version=' "${1}"; then
        log_error "NOT ENCRYPTED: ${1}"
        exit 1
    fi
}

# Decrypt a file in place and encrypt it again at exit.
#
# Run this inside a sub-shell to encrypt the file again as soon as it's no
# longer used. For example:
# (
#   sops_decrypt config
#   command --config config
# )
# TODO: This is bad since it makes the decrypted secrets touch the filesystem.
#       We should try to remove this asap. Currently required by rke and Helm2.
sops_decrypt() {
    log_info "Decrypting ${1}"

    sops_decrypt_verify "${1}"

    sops -d -i "${1}"
    append_trap "sops_encrypt ${1}" EXIT
}

# Temporarily decrypts a file and runs a command that can read it once.
sops_exec_file() {
    sops_decrypt_verify "${1}"

    sops exec-file "${1}" "${2}"
}

# The same as sops_exec_file except the decrypted file is written as a normal
# file on disk while it's being used.
# This should only be used if absolutely necessary, for example where the
# decrypted file needs to be read more than once.
# TODO: Try to eliminate this in the future.
sops_exec_file_no_fifo() {
    sops_decrypt_verify "${1}"

    sops exec-file --no-fifo "${1}" "${2}"
}

# Temporarily decrypts a file and loads the content as environment variables
# that will only be available to a command.
sops_exec_env() {
    sops_decrypt_verify "${1}"

    sops exec-env "${1}" "${2}"
}

# Run a command with the secrets config options available as environment
# variables.
with_config_secrets() {
    sops_decrypt_verify "${secrets_file}"

    sops_exec_env "${secrets_file}" "${*}"
}

# Run a command with a temporary SSH agent with a temporarily decrypted SSH
# key added to it. The agent is killed at exit.
#
# Run this inside a sub-shell to kill the SSH agent as soon as it's no longer
# used. For example:
# (
#   with_ssh_agent [key] ssh [ip]
# )
with_ssh_agent() {
    ssh_key="${1}"
    shift

    log_info "Starting SSH agent and adding private SSH key: ${ssh_key}"

    kill_agent() {
        log_info "Killing SSH agent for SSH key: ${ssh_key}"
        kill ${SSH_AGENT_PID}
    }

    eval $(ssh-agent -a "${ssh_auth_sock}") > /dev/null
    append_trap kill_agent EXIT

    sops_exec_file "${ssh_key}" 'ssh-add "{}" 2>/dev/null; '"${*}"
}

# Run a command with KUBECONFIG set to a temporarily decrypted file.
with_kubeconfig() {
    kubeconfig="${1}"
    shift
    # TODO: Can't use a FIFO since we can't know that the kubeconfig is not
    #       read multiple times. Let's try to eliminate the need for writing
    #       the kubeconfig to disk in the future.
    sops_exec_file_no_fifo "${kubeconfig}" 'KUBECONFIG="{}" '"${*}"
}

# Runs a command with S3COMMAND_CONFIG_FILE set to a temporarily decrypted
# file.
with_s3cfg() {
    s3cfg="${1}"
    shift
    # TODO: Can't use a FIFO since the s3cfg is read mulitiple times when a
    #       bucket needs to be created.
    sops_exec_file_no_fifo "${s3cfg}" 'S3COMMAND_CONFIG_FILE="{}" '"${*}"
}
