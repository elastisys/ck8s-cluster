package openstack

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
)

// Cluster TODO
type Cluster struct {
	OpenstackConfig `mapstructure:",squash"`
	OpenstackSecret `mapstructure:",squash"`
	OpenstackTFVars `mapstructure:",squash"`
}

// Config TODO
func (e *Cluster) Config() interface{} {
	return &e.OpenstackConfig
}

// Secret TODO
func (e *Cluster) Secret() interface{} {
	return &e.OpenstackSecret
}

// TFVars TODO
func (e *Cluster) TFVars() interface{} {
	return &e.OpenstackTFVars
}

// State TODO
func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := DefaultState(e)
	return &tfOutput, loadState(&tfOutput)
}

// DefaultState TODO
func DefaultState(cluster *Cluster) TerraformOutput {
	return TerraformOutput{
		ClusterType: cluster.ClusterType,
		ClusterName: cluster.Name(),

		ControlPlanePort: 6443,

		// TODO: This value currently needs to align with what is set in the
		//		 Terraform code. We should expose this as an outer variable and
		//		 forward it from here instead.
		PrivateNetworkCIDR: "172.0.10.0/24",

		// Since MTU for the interface is 1500 calico should be set to 1480
		CalicoMTU: 1480,

		KubeadmInitCloudProvider:   "openstack",
		KubeadmInitCloudConfigPath: "/etc/kubernetes/cloud.conf",
	}
}

// Name TODO
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

	return e.OpenstackConfig.Name()
}

// TerraformEnv TODO
func (e *Cluster) TerraformEnv(sshPublicKey string) map[string]string {
	env := e.BaseConfig.TerraformEnv(sshPublicKey)
	env["OS_USERNAME"] = e.Username
	env["OS_PASSWORD"] = e.Password
	env["OS_IDENTITY_API_VERSION"] = e.IdentityAPIVersion
	env["OS_AUTH_URL"] = e.AuthURL
	env["OS_REGION_NAME"] = e.RegionName
	env["OS_USER_DOMAIN_NAME"] = e.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = e.ProjectDomainName
	env["OS_PROJECT_ID"] = e.ProjectID
	return env
}

// AnsibleEnv TODO
func (e *Cluster) AnsibleEnv() map[string]string {
	env := e.BaseConfig.AnsibleEnv()
	env["OS_USERNAME"] = e.Username
	env["OS_PASSWORD"] = e.Password
	env["OS_IDENTITY_API_VERSION"] = e.IdentityAPIVersion
	env["OS_AUTH_URL"] = e.AuthURL
	env["OS_REGION_NAME"] = e.RegionName
	env["OS_USER_DOMAIN_NAME"] = e.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = e.ProjectDomainName
	env["OS_PROJECT_ID"] = e.ProjectID
	return env
}
