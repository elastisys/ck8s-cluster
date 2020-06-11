package client

import (
	"go.mozilla.org/sops/v3/decrypt"

	"github.com/elastisys/ck8s/api"
)

type SOPSConfigCreationRule struct {
	PGP string `yaml:"pgp"`
}

type SOPSConfig struct {
	CreationRules []SOPSConfigCreationRule `yaml:"creation_rules"`
}

func NewSOPSConfig(pgpFingerprint string) SOPSConfig {
	return SOPSConfig{
		CreationRules: []SOPSConfigCreationRule{{
			PGP: pgpFingerprint,
		}},
	}
}

func sopsDecrypt(path api.Path) ([]byte, error) {
	return decrypt.File(path.Path, path.Format)
}
