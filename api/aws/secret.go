package aws

type AWSSecret struct {
	AWSAccessKeyID     string `mapstructure:"aws_access_key" yaml:"aws_access_key" validate:"required"`
	AWSSecretAccessKey string `mapstructure:"aws_secret_key" yaml:"aws_secret_key" validate:"required"`

	DNSAccessKeyID     string `mapstructure:"dns_access_key" yaml:"dns_access_key" validate:"required"`
	DNSSecretAccessKey string `mapstructure:"dns_secret_key" yaml:"dns_secret_key" validate:"required"`
}
