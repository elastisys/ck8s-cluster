package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type Secret struct {
	api.BaseSecret `mapstructure:",squash" yaml:",inline"`

	Username string `mapstructure:"os_username" yaml:"os_username" validate:"required"`
	Password string `mapstructure:"os_password" yaml:"os_password" validate:"required"`

	AWSAccessKeyID     string `mapstructure:"aws_access_key_id" yaml:"aws_access_key_id" validate:"required"`
	AWSSecretAccessKey string `mapstructure:"aws_secret_access_key" yaml:"aws_secret_access_key" validate:"required"`
}
