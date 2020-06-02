package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

type ExoscaleSecret struct {
	api.BaseSecret `mapstructure:",squash"`

	APIKey    string `mapstructure:"TF_VAR_exoscale_api_key" validate:"required"`
	SecretKey string `mapstructure:"TF_VAR_exoscale_secret_key" validate:"required"`
}
