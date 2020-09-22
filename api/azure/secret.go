package azure

import (
	"github.com/elastisys/ck8s/api"
)

type AzureSecret struct {
	api.BaseSecret `mapstructure:",squash" yaml:",inline"`

	ClientID     string `mapstructure:"client_id" yaml:"client_id" validate:"required"`
	ClientSecret string `mapstructure:"client_secret" yaml:"client_secret" validate:"required"`
}
