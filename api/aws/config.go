package aws

import (
	"github.com/elastisys/ck8s/api"
)

type AWSConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`

	S3Region string `mapstructure:"s3_region" yaml:"s3_region" validate:"required"`
}
