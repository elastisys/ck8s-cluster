package openstack

import (
	"github.com/elastisys/ck8s/api"
)

// StateHelper TODO
func StateHelper(
	clusterType api.ClusterType,
	clusterName string,
) TerraformOutput {
	return TerraformOutput{
		ClusterType: clusterType,
		ClusterName: clusterName,

		ControlPlanePort: 6443,

		// TODO: This value currently needs to align with what is set in the
		//		 Terraform code. We should expose this as an outer variable and
		//		 forward it from here instead.
		PrivateNetworkCIDR: "",

		// Since MTU for the interface is 1500 calico should be set to 1480
		CalicoMTU: 1480,

		KubeadmInitCloudProvider:   "openstack",
		KubeadmInitCloudConfigPath: "/etc/kubernetes/cloud.conf",
	}
}

// TerraformEnvHelper TODO
func TerraformEnvHelper(
	config OpenstackConfig,
	secret OpenstackSecret,
	sshPublicKey string,
) map[string]string {
	env := api.TerraformEnvHelper(&config.BaseConfig, sshPublicKey)

	env["OS_USERNAME"] = secret.Username
	env["OS_PASSWORD"] = secret.Password
	env["OS_IDENTITY_API_VERSION"] = config.IdentityAPIVersion
	env["OS_AUTH_URL"] = config.AuthURL
	env["OS_REGION_NAME"] = config.RegionName
	env["OS_USER_DOMAIN_NAME"] = config.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = config.ProjectDomainName
	env["OS_PROJECT_ID"] = config.ProjectID

	return env
}

// AnsibleEnvHelper TODO
func AnsibleEnvHelper(
	config OpenstackConfig,
	secret OpenstackSecret,
) map[string]string {
	env := map[string]string{}
	env["OS_USERNAME"] = secret.Username
	env["OS_PASSWORD"] = secret.Password
	env["OS_IDENTITY_API_VERSION"] = config.IdentityAPIVersion
	env["OS_AUTH_URL"] = config.AuthURL
	env["OS_REGION_NAME"] = config.RegionName
	env["OS_USER_DOMAIN_NAME"] = config.UserDomainName
	env["OS_PROJECT_DOMAIN_NAME"] = config.ProjectDomainName
	env["OS_PROJECT_ID"] = config.ProjectID
	return env
}

func LookupMachinePartHelper(
	tfvars *OpenstackTFVars,
	cluster api.ClusterType,
	nodeType api.NodeType,
) TfvarsMachinePart {
	return map[api.ClusterType]map[api.NodeType]TfvarsMachinePart{
		api.ServiceCluster: {
			api.Master: {
				&tfvars.MasterNamesSC,
				tfvars.MasterNameSizeMapSC,
			},
			api.Worker: {
				&tfvars.WorkerNamesSC,
				tfvars.WorkerNameSizeMapSC,
			},
		},
		api.WorkloadCluster: {
			api.Master: {
				&tfvars.MasterNamesWC,
				tfvars.MasterNameSizeMapWC,
			},
			api.Worker: {
				&tfvars.WorkerNamesWC,
				tfvars.WorkerNameSizeMapWC,
			},
		},
	}[cluster][nodeType]
}
