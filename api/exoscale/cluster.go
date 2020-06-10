package exoscale

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

type Cluster struct {
	ExoscaleConfig `mapstructure:",squash"`
	ExoscaleSecret `mapstructure:",squash"`
	ExoscaleTFVars `mapstructure:",squash"`
}

func (e *Cluster) Config() interface{} {
	return &e.ExoscaleConfig
}

func (e *Cluster) Secret() interface{} {
	return &e.ExoscaleSecret
}

func (e *Cluster) TFVars() interface{} {
	return &e.ExoscaleTFVars
}

func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := terraformOutput{
		ClusterType: e.ClusterType,
		ClusterName: e.Name(),

		ControlPlanePort: 7443,

		// TODO: This value currently needs to align with what is set in the
		//		 Terraform code. We should expose this as an outer variable and
		//		 forward it from here instead.
		PrivateNetworkCIDR: "172.0.10.0/24",

		CalicoMTU: 1480,

		InternalLoadBalancerAnsibleGroups: []string{"nodes"},
	}
	return &tfOutput, loadState(&tfOutput)
}

func (e *Cluster) Name() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		if e.PrefixSC != "" {
			return e.PrefixSC
		}
	case api.WorkloadCluster:
		if e.PrefixWC != "" {
			return e.PrefixWC
		}
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}

	return e.ExoscaleConfig.Name()
}

func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := e.BaseConfig.TerraformEnv(sshPublicKey)
	env["TF_VAR_exoscale_api_key"] = e.APIKey
	env["TF_VAR_exoscale_secret_key"] = e.SecretKey
	return env
}