package aws

import (
	"github.com/elastisys/ck8s/api"
)

type AWSConfig struct {
	api.BaseConfig `mapstructure:",squash"`

	S3Region string `mapstructure:"S3_REGION" validate:"required"`
}
