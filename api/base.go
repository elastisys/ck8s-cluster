package api

import "fmt"

type BaseConfig struct {
	// TODO: We'd like to get rid of this but it's not currently possible since
	//       we store both the service cluster and the workload cluster in the
	//       same Terraform state.
	ClusterType ClusterType `validate:"required"`

	CloudProviderType CloudProviderType `mapstructure:"CLOUD_PROVIDER" validate:"required"`

	EnvironmentName string `mapstructure:"ENVIRONMENT_NAME" validate:"required"`

	ControlPlaneEndpoint string `validate:"required"`

	ControlPlanePort int `validate:"required"`

	PrivateNetworkCIDR string

	// KubeadmInitCloudProvider and KubeadmInitCloudConfigPath only needs to
	// be set if cloud provider specific config is to be used in the
	// Kubernetes cluster.
	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string

	CalicoMTU int `validate:"required"`

	KubeadmInitExtraArgs string

	InternalLoadBalancerAnsibleGroups []string

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

func EmptyBaseConfig(clusterType ClusterType) BaseConfig {
	return BaseConfig{
		ClusterType: clusterType,
	}
}

func (b *BaseConfig) Name() string {
	switch b.ClusterType {
	case ServiceCluster:
		return b.EnvironmentName + "-service-cluster"
	case WorkloadCluster:
		return b.EnvironmentName + "-workload-cluster"
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", b.ClusterType))
	}
}

func (b *BaseConfig) TerraformWorkspace() string {
	return b.EnvironmentName
}

func (b *BaseConfig) CloudProvider() CloudProviderType {
	return b.CloudProviderType
}

func (b *BaseConfig) TerraformEnv(sshPublicKey string) map[string]string {
	var currentSSHPublicKeyTFVar, otherSSHPublicKeyTFVar string
	switch b.ClusterType {
	case ServiceCluster:
		currentSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_sc"
		otherSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_wc"
	case WorkloadCluster:
		currentSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_wc"
		otherSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_sc"
	}
	return map[string]string{
		"TF_VAR_dns_prefix": b.DNSPrefix,

		currentSSHPublicKeyTFVar: sshPublicKey,
		otherSSHPublicKeyTFVar:   "",
	}
}

func (b *BaseConfig) S3Buckets() map[string]string {
	return map[string]string{
		"S3_ES_BACKUP_BUCKET_NAME":  b.S3BucketNameElasticsearch,
		"S3_HARBOR_BUCKET_NAME":     b.S3BucketNameHarbor,
		"S3_INFLUX_BUCKET_NAME":     b.S3BucketNameInfluxDB,
		"S3_SC_FLUENTD_BUCKET_NAME": b.S3BucketNameFluentd,
		"S3_VELERO_BUCKET_NAME":     b.S3BucketNameVelero,
	}
}
