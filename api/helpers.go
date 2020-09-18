package api

import "fmt"

func NameHelper(config *BaseConfig) string {
	switch config.ClusterType {
	case ServiceCluster:
		return config.EnvironmentName + "-service-cluster"
	case WorkloadCluster:
		return config.EnvironmentName + "-workload-cluster"
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", config.ClusterType))
	}
}

func S3BucketsHelper(config *BaseConfig) map[string]string {
	return map[string]string{
		"S3_ES_BACKUP_BUCKET_NAME":  config.S3BucketNameElasticsearch,
		"S3_HARBOR_BUCKET_NAME":     config.S3BucketNameHarbor,
		"S3_INFLUX_BUCKET_NAME":     config.S3BucketNameInfluxDB,
		"S3_SC_FLUENTD_BUCKET_NAME": config.S3BucketNameFluentd,
		"S3_VELERO_BUCKET_NAME":     config.S3BucketNameVelero,
	}
}

func TerraformEnvHelper(
	config *BaseConfig,
	sshPublicKey string,
) map[string]string {
	var currentSSHPublicKeyTFVar, otherSSHPublicKeyTFVar string
	switch config.ClusterType {
	case ServiceCluster:
		currentSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_sc"
		otherSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_wc"
	case WorkloadCluster:
		currentSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_wc"
		otherSSHPublicKeyTFVar = "TF_VAR_ssh_pub_key_sc"
	}
	return map[string]string{
		"TF_VAR_dns_prefix": config.DNSPrefix,

		currentSSHPublicKeyTFVar: sshPublicKey,
		otherSSHPublicKeyTFVar:   "",
	}
}
