package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

func Empty(clusterType api.ClusterType) *ExoscaleCluster {
	return &ExoscaleCluster{
		BaseConfig:   api.EmptyBaseConfig(clusterType),
		TFVarsConfig: &TFVarsConfig{},
	}
}

func Default(clusterType api.ClusterType) *ExoscaleCluster {
	config := Empty(clusterType)

	config.ControlPlaneEndpoint = "127.0.0.1"
	config.ControlPlanePort = 7443
	// TODO: This value currently needs to align with what is set in the
	//		 Terraform code. We should expose this as an outer variable and
	//		 forward it from here instead.
	config.PrivateNetworkCIDR = "172.0.10.0/24"
	config.CalicoMTU = 1480
	config.InternalLoadBalancerAnsibleGroups = []string{"nodes"}

	return config
}
