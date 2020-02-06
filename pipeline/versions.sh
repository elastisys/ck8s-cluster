# Variables
export KUBECONFIG=$(pwd)/kube_config_eck-wc.yaml
./release/get-versions.sh
export ECK_KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml
./release/get-versions.sh
cat release/version.json > "${GITHUB_WORKSPACE}/version.json"