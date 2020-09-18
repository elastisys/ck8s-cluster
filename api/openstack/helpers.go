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
