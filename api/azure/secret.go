package azure

import (
	"github.com/elastisys/ck8s/api"
)

type AzureSecret struct {
	api.BaseSecret `mapstructure:",squash"`

	APIKey    string `mapstructure:"AZURE_KEY" validate:"required"`
	SecretKey string `mapstructure:"AZURE_SECRET" validate:"required"`
}
