package api

func DefaultBaseConfig(
	clusterType ClusterType,
	cloudProviderType CloudProviderType,
	clusterName string,
) *BaseConfig {
	return &BaseConfig{
		ClusterType:               clusterType,
		CloudProviderType:         cloudProviderType,
		EnvironmentName:           clusterName,
		DNSPrefix:                 clusterName,
		S3BucketNameHarbor:        clusterName + "-harbor",
		S3BucketNameVelero:        clusterName + "-velero",
		S3BucketNameElasticsearch: clusterName + "-es-backup",
		S3BucketNameInfluxDB:      clusterName + "-influxdb",
		S3BucketNameFluentd:       clusterName + "-sc-logs",
	}
}

type BaseConfig struct {
	// TODO: We'd like to get rid of this but it's not currently possible since
	//       we store both the service cluster and the workload cluster in the
	//       same Terraform state.
	ClusterType ClusterType `validate:"required"`

	CloudProviderType CloudProviderType `mapstructure:"CLOUD_PROVIDER" validate:"required"`

	EnvironmentName string `mapstructure:"ENVIRONMENT_NAME" validate:"required"`

	DNSPrefix string `mapstructure:"TF_VAR_dns_prefix" validate:"required"`

	S3BucketNameElasticsearch string `mapstructure:"S3_ES_BACKUP_BUCKET_NAME" validate:"required"`
	S3BucketNameHarbor        string `mapstructure:"S3_HARBOR_BUCKET_NAME" validate:"required"`
	S3BucketNameInfluxDB      string `mapstructure:"S3_INFLUX_BUCKET_NAME" validate:"required"`
	S3BucketNameFluentd       string `mapstructure:"S3_SC_FLUENTD_BUCKET_NAME" validate:"required"`
	S3BucketNameVelero        string `mapstructure:"S3_VELERO_BUCKET_NAME" validate:"required"`
}

type BaseSecret struct {
	S3AccessKey string `mapstructure:"S3_ACCESS_KEY" validate:"required"`
	S3SecretKey string `mapstructure:"S3_SECRET_KEY" validate:"required"`
}
