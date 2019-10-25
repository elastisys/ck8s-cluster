# This script downloads the info at the given vault path, unzips it,
# and then saves it to the given path.
# Assumes that the info is a .tgz archive.

: "${VAULT_TOKEN:?Missing VAULT_TOKEN}"
: "${VAULT_ADDR:?Missing VAULT_ADDR}"

if [[ "$#" -lt 2 ]]
then 
  >&2 echo "Usage: download-info.sh <local_path_to_info> <vault_path_to_info>"
  >&2 echo "E.g. download-info.sh a1-demo-1/ eck/v1/exoscale/a1-demo-1"
  exit 1
fi

local_path=$1
vault_path=$2

vault kv get -field info $vault_path | base64 -d > tmp.tgz
mkdir $local_path -p
tar -xf tmp.tgz -C $local_path
rm tmp.tgz