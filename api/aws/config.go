package aws

import (
	"github.com/elastisys/ck8s/api"
)

type AWSConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`
}
