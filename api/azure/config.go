package azure

import (
	"github.com/elastisys/ck8s/api"
)

type AzureConfig struct {
	api.BaseConfig `mapstructure:",squash"`

	S3RegionAddress string `mapstructure:"S3_REGION_ADDRESS" validate:"required"`
}
