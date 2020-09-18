package aws

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

//Cluster TODO
type Cluster struct {
	config AWSConfig `mapstructure:",squash"`
	secret AWSSecret `mapstructure:",squash"`
	tfvars AWSTFVars `mapstructure:",squash"`
}

//Config TODO
func (e *Cluster) Config() interface{} {
	return &e.config
}

//Secret TODO
func (e *Cluster) Secret() interface{} {
	return &e.secret
}

//TFVars TODO
func (e *Cluster) TFVars() interface{} {
	return &e.tfvars
}

//State TODO
func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := terraformOutput{
		ClusterType: e.config.ClusterType,
		ClusterName: e.Name(),

		ControlPlanePort: 6443,

		// TODO: This value currently needs to align with what is set in the
		//		 Terraform code. We should expose this as an outer variable and
		//		 forward it from here instead.
		PrivateNetworkCIDR: "",

		CalicoMTU: 1480,

		KubeadmInitCloudProvider: "aws",
	}
	return &tfOutput, loadState(&tfOutput)
}

//CloudProvider TODO
func (e *Cluster) CloudProvider() api.CloudProviderType {
	return e.config.CloudProviderType
}

//CloudProviderVars TODO
func (e *Cluster) CloudProviderVars(state api.ClusterState) interface{} {
	return nil
}

//Name TODO
func (e *Cluster) Name() string {
	switch e.config.ClusterType {
	case api.ServiceCluster:
		if e.tfvars.PrefixSC != "" {
			return e.tfvars.PrefixSC
		}
	case api.WorkloadCluster:
		if e.tfvars.PrefixWC != "" {
			return e.tfvars.PrefixWC
		}
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.config.ClusterType))
	}

	return api.NameHelper(&e.config.BaseConfig)
}

//S3Buckets TODO
func (e *Cluster) S3Buckets() map[string]string {
	return api.S3BucketsHelper(&e.config.BaseConfig)
}

//TerraformWorkspace TODO
func (e *Cluster) TerraformWorkspace() string {
	return e.config.EnvironmentName
}

//TerraformEnv TODO
func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := api.TerraformEnvHelper(&e.config.BaseConfig, sshPublicKey)
	env["TF_VAR_aws_access_key"] = e.secret.AWSAccessKeyID
	env["TF_VAR_aws_secret_key"] = e.secret.AWSSecretAccessKey
	env["TF_VAR_dns_access_key"] = e.secret.DNSAccessKeyID
	env["TF_VAR_dns_secret_key"] = e.secret.DNSSecretAccessKey
	return env
}

//AnsibleEnv TODO
func (e *Cluster) AnsibleEnv() map[string]string {
	return map[string]string{}
}
