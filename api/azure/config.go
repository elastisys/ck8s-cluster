package azure

import (
	"github.com/elastisys/ck8s/api"
)

type AzureConfig struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`

	S3RegionAddress string `mapstructure:"s3_region_address" yaml:"s3_region_address" validate:"required"`

	TenantID       string `mapstructure:"tenant_id" yaml:"tenant_id" validate:"required"`
	SubscriptionID string `mapstructure:"subscription_id" yaml:"subscription_id" validate:"required"`
	Location       string `mapstructure:"location" yaml:"location" validate:"required"`
}
