package aws

import (
	"github.com/elastisys/ck8s/api"
)

type AWSSecret struct {
	api.BaseSecret `mapstructure:",squash"`

	AWSAccessKeyID     string `mapstructure:"TF_VAR_aws_access_key" validate:"required"`
	AWSSecretAccessKey string `mapstructure:"TF_VAR_aws_secret_key" validate:"required"`

	DNSAccessKeyID     string `mapstructure:"TF_VAR_dns_access_key" validate:"required"`
	DNSSecretAccessKey string `mapstructure:"TF_VAR_dns_secret_key" validate:"required"`
}
