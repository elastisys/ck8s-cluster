package client

import (
	"go.mozilla.org/sops/v3/decrypt"

	"github.com/elastisys/ck8s/api"
)

func sopsDecrypt(path api.Path) ([]byte, error) {
	return decrypt.File(path.Path, path.Format)
}
