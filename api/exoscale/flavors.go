package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

func Empty(clusterType api.ClusterType) *Cluster {
	return &Cluster{
		ExoscaleConfig: ExoscaleConfig{
			BaseConfig: api.EmptyBaseConfig(clusterType),
		},
		ExoscaleSecret: ExoscaleSecret{
			BaseSecret: api.BaseSecret{},
		},
		ExoscaleTFVars: ExoscaleTFVars{},
	}
}

func Default(clusterType api.ClusterType) *Cluster {
	cluster := Empty(clusterType)

	cluster.ControlPlaneEndpoint = "127.0.0.1"
	cluster.ControlPlanePort = 7443
	// TODO: This value currently needs to align with what is set in the
	//		 Terraform code. We should expose this as an outer variable and
	//		 forward it from here instead.
	cluster.PrivateNetworkCIDR = "172.0.10.0/24"
	cluster.CalicoMTU = 1480
	cluster.InternalLoadBalancerAnsibleGroups = []string{"nodes"}

	return cluster
}
