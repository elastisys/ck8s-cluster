package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

type ExoscaleConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`

	S3RegionAddress string `mapstructure:"s3_region_address" yaml:"s3_region_address" validate:"required"`
}
