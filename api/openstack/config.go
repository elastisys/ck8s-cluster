package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type OpenstackConfig struct {
	api.BaseConfig `mapstructure:",squash"`

	IdentityAPIVersion string `mapstructure:"OS_IDENTITY_API_VERSION" validate:"required"`
	AuthURL            string `mapstructure:"OS_AUTH_URL" validate:"required"`
	RegionName         string `mapstructure:"OS_REGION_NAME" validate:"required"`
	UserDomainName     string `mapstructure:"OS_PROJECT_DOMAIN_NAME" validate:"required"`
	ProjectDomainName  string `mapstructure:"OS_PROJECT_DOMAIN_NAME" validate:"required"`
	ProjectID          string `mapstructure:"OS_PROJECT_ID" validate:"required"`

	S3RegionAddress string `mapstructure:"S3_REGION_ADDRESS" validate:"required"`
}
