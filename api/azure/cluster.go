package azure

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

type Cluster struct {
	config AzureConfig `mapstructure:",squash"`
	secret AzureSecret `mapstructure:",squash"`
	tfvars AzureTFVars `mapstructure:",squash"`
}

func (e *Cluster) Config() interface{} {
	return &e.config
}

func (e *Cluster) Secret() interface{} {
	return &e.secret
}

func (e *Cluster) TFVars() interface{} {
	return &e.tfvars
}

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
		PrivateNetworkCIDR: "10.0.10.0/24",

		CalicoMTU: 1480,

		KubeadmInitCloudProvider: "azure",
	}
	return &tfOutput, loadState(&tfOutput)
}

func (e *Cluster) CloudProvider() api.CloudProviderType {
	return e.config.CloudProviderType
}

func (e *Cluster) CloudProviderVars(state api.ClusterState) interface{} {
	return nil
}

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

func (e *Cluster) S3Buckets() map[string]string {
	return api.S3BucketsHelper(&e.config.BaseConfig)
}

func (e *Cluster) TerraformWorkspace() string {
	return e.config.EnvironmentName
}

func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := api.TerraformEnvHelper(&e.config.BaseConfig, sshPublicKey)
	env["TODO-TF_VAR_exoscale_api_key"] = e.secret.APIKey
	env["TODO-TF_VAR_exoscale_secret_key"] = e.secret.SecretKey
	return env
}

func (e *Cluster) AnsibleEnv() map[string]string {
	return map[string]string{}
}
