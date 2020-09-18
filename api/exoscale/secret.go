package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

type ExoscaleSecret struct {
	api.BaseSecret `mapstructure:",squash" yaml:",inline"`

	APIKey    string `mapstructure:"exoscale_api_key" yaml:"exoscale_api_key" validate:"required"`
	SecretKey string `mapstructure:"exoscale_secret_key" yaml:"exoscale_secret_key" validate:"required"`
}
