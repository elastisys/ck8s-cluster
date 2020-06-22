package openstack

import (
	"github.com/elastisys/ck8s/api"
)

type OpenstackSecret struct {
	api.BaseSecret `mapstructure:",squash"`

	Username string `mapstructure:"OS_USERNAME" validate:"required"`
	Password string `mapstructure:"OS_PASSWORD" validate:"required"`

	AWSAccessKeyID     string `mapstructure:"AWS_ACCESS_KEY_ID" validate:"required"`
	AWSSecretAccessKey string `mapstructure:"AWS_SECRET_ACCESS_KEY" validate:"required"`
}
