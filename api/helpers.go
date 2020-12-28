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
		currentSSHPublicKeyTFVar: sshPublicKey,
		otherSSHPublicKeyTFVar:   "",
	}
}
