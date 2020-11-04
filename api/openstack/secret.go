package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type Secret struct {
	api.BaseSecret `mapstructure:",squash" yaml:",inline"`

	Username string `mapstructure:"os_username" yaml:"os_username" validate:"required"`
	Password string `mapstructure:"os_password" yaml:"os_password" validate:"required"`
}
