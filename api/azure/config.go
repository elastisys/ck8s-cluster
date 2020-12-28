package azure

import (
	"github.com/elastisys/ck8s/api"
)

type AzureConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`

	TenantID       string `mapstructure:"tenant_id" yaml:"tenant_id" validate:"required"`
	SubscriptionID string `mapstructure:"subscription_id" yaml:"subscription_id" validate:"required"`
	Location       string `mapstructure:"location" yaml:"location" validate:"required"`
}
