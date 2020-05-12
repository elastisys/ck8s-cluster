SCRIPTS_PATH="$(dirname "$(readlink -f "$BASH_SOURCE")")"
set -e

echo Testing OPA polices
opa test ${SCRIPTS_PATH}/../../../../helmfile/charts/gatekeeper-templates/policies/ -v
