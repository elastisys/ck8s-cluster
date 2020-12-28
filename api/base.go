package api

type BaseConfig struct {
	// TODO: We'd like to get rid of this but it's not currently possible since
	//       we store both the service cluster and the workload cluster in the
	//       same Terraform state.
	ClusterType ClusterType `yaml:"-" validate:"required"`

	CloudProviderType CloudProviderType `mapstructure:"cloud_provider" yaml:"cloud_provider" validate:"required"`

	EnvironmentName string `mapstructure:"environment_name" yaml:"environment_name" validate:"required"`

	OIDCIssuerURL     string `mapstructure:"oidc_issuer_url" yaml:"oidc_issuer_url" validate:"required"`
	OIDCClientId      string `mapstructure:"oidc_client_id" yaml:"oidc_client_id" validate:"required"`
	OIDCUsernameClaim string `mapstructure:"oidc_username_claim" yaml:"oidc_username_claim" validate:"required"`
	OIDCGroupsClaim   string `mapstructure:"oidc_groups_claim" yaml:"oidc_groups_claim" validate:"required"`
}

func DefaultBaseConfig(
	clusterType ClusterType,
	cloudProviderType CloudProviderType,
	clusterName string,
) *BaseConfig {
	return &BaseConfig{
		ClusterType:       clusterType,
		CloudProviderType: cloudProviderType,
		EnvironmentName:   clusterName,
		OIDCIssuerURL:     "set-me",
		OIDCClientId:      "kubelogin",
		OIDCUsernameClaim: "email",
		OIDCGroupsClaim:   "groups",
	}
}
