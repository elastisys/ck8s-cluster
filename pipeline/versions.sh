# Variables
export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
${GITHUB_WORKSPACE}/release/get-versions.sh
export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
${GITHUB_WORKSPACE}/release/get-versions.sh
cat release/version.json > "${GITHUB_WORKSPACE}/version.json"