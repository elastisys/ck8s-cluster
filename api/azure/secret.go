package azure

type AzureSecret struct {
	ClientID     string `mapstructure:"client_id" yaml:"client_id" validate:"required"`
	ClientSecret string `mapstructure:"client_secret" yaml:"client_secret" validate:"required"`
}
