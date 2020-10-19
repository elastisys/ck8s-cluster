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

	S3BucketNameElasticsearch string `mapstructure:"s3_es_backup_bucket_name" yaml:"s3_es_backup_bucket_name" validate:"required"`
	S3BucketNameHarbor        string `mapstructure:"s3_harbor_bucket_name" yaml:"s3_harbor_bucket_name" validate:"required"`
	S3BucketNameInfluxDB      string `mapstructure:"s3_influx_bucket_name" yaml:"s3_influx_bucket_name" validate:"required"`
	S3BucketNameFluentd       string `mapstructure:"s3_sc_fluentd_bucket_name" yaml:"s3_sc_fluentd_bucket_name" validate:"required"`
	S3BucketNameVelero        string `mapstructure:"s3_velero_bucket_name" yaml:"s3_velero_bucket_name" validate:"required"`
}

func DefaultBaseConfig(
	clusterType ClusterType,
	cloudProviderType CloudProviderType,
	clusterName string,
) *BaseConfig {
	return &BaseConfig{
		ClusterType:               clusterType,
		CloudProviderType:         cloudProviderType,
		EnvironmentName:           clusterName,
		OIDCIssuerURL:             "",
		OIDCClientId:              "kubelogin",
		OIDCUsernameClaim:         "email",
		OIDCGroupsClaim:           "groups",
		S3BucketNameHarbor:        clusterName + "-harbor",
		S3BucketNameVelero:        clusterName + "-velero",
		S3BucketNameElasticsearch: clusterName + "-es-backup",
		S3BucketNameInfluxDB:      clusterName + "-influxdb",
		S3BucketNameFluentd:       clusterName + "-sc-logs",
	}
}

type BaseSecret struct {
	S3AccessKey string `mapstructure:"s3_access_key" yaml:"s3_access_key" validate:"required"`
	S3SecretKey string `mapstructure:"s3_secret_key" yaml:"s3_secret_key" validate:"required"`
}

func DefaultBaseSecret() *BaseSecret {
	return &BaseSecret{
		S3AccessKey: "changeme",
		S3SecretKey: "changeme",
	}
}
