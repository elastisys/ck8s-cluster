package openstack

type Secret struct {
	Username string `mapstructure:"os_username" yaml:"os_username" validate:"required"`
	Password string `mapstructure:"os_password" yaml:"os_password" validate:"required"`
}
