package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

type ExoscaleConfig struct {
	api.BaseConfig `mapstructure:",squash"`

	S3RegionAddress string `mapstructure:"S3_REGION_ADDRESS" validate:"required"`
}
