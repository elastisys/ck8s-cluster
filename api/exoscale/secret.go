package exoscale

type ExoscaleSecret struct {
	APIKey    string `mapstructure:"exoscale_api_key" yaml:"exoscale_api_key" validate:"required"`
	SecretKey string `mapstructure:"exoscale_secret_key" yaml:"exoscale_secret_key" validate:"required"`
}
