package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type OpenstackSecret struct {
	api.BaseSecret `mapstructure:",squash"`

	Username string `mapstructure:"OS_USERNAME" validate:"required"`
	Password string `mapstructure:"OS_PASSWORD" validate:"required"`
}
