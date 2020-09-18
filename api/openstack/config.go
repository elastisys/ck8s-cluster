package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type Config struct {
	api.BaseConfig `mapstructure:",squash" yaml:",inline"`

	IdentityAPIVersion string `mapstructure:"os_identity_api_version" yaml:"os_identity_api_version" validate:"required"`
	AuthURL            string `mapstructure:"os_auth_url" yaml:"os_auth_url" validate:"required"`
	RegionName         string `mapstructure:"os_region_name" yaml:"os_region_name" validate:"required"`
	UserDomainName     string `mapstructure:"os_user_domain_name" yaml:"os_user_domain_name" validate:"required"`
	ProjectDomainName  string `mapstructure:"os_project_domain_name" yaml:"os_project_domain_name" validate:"required"`
	ProjectID          string `mapstructure:"os_project_id" yaml:"os_project_id" validate:"required"`

	S3RegionAddress string `mapstructure:"s3_region_address" yaml:"s3_region_address" validate:"required"`
}
