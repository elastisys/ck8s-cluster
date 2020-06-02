package exoscale

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

type ExoscaleCluster struct {
	api.BaseConfig `mapstructure:",squash"`

	*TFVarsConfig

	APIKey    string `mapstructure:"TF_VAR_exoscale_api_key" validate:"required"`
	SecretKey string `mapstructure:"TF_VAR_exoscale_secret_key" validate:"required"`

	S3RegionAddress string `mapstructure:"S3_REGION_ADDRESS" validate:"required"`
}

func (e *ExoscaleCluster) TFVars() interface{} {
	return e.TFVarsConfig
}

func (e *ExoscaleCluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := terraformOutput{
		ClusterType: e.ClusterType,
		ClusterName: e.Name(),
	}
	return &tfOutput, loadState(&tfOutput)
}

func (e *ExoscaleCluster) Name() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		if e.TFVarsConfig.PrefixSC != "" {
			return e.TFVarsConfig.PrefixSC
		}
	case api.WorkloadCluster:
		if e.TFVarsConfig.PrefixWC != "" {
			return e.TFVarsConfig.PrefixWC
		}
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}

	return e.BaseConfig.Name()
}

func (e *ExoscaleCluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := e.BaseConfig.TerraformEnv(sshPublicKey)
	env["TF_VAR_exoscale_api_key"] = e.APIKey
	env["TF_VAR_exoscale_secret_key"] = e.SecretKey
	return env
}
