# This script will take everything in the indicated folder, compress it,
# and then upload it to vault at the given path.

: "${VAULT_TOKEN:?Missing VAULT_TOKEN}"
: "${VAULT_ADDR:?Missing VAULT_ADDR}"

if [[ "$#" -lt 2 ]]
then 
  >&2 echo "Usage: upload-info.sh <local_path_to_item> <vault_path_to_item>"
  >&2 echo "E.g. upload-info.sh a1-demo-1/ eck/v1/exoscale/a1-demo-1"
  exit 1
fi

local_path=$1
vault_path=$2

find $local_path -printf "%P\n" | tar -czf tmp.tgz --no-recursion -C $local_path -T -
base64 tmp.tgz | vault kv put $vault_path info=-
rm tmp.tgz