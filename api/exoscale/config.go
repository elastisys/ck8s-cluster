package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

type ExoscaleConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`
}
