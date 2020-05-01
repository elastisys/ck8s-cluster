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
	config.CalicoMTU = 1480
	config.InternalLoadBalancerAnsibleGroups = []string{"nodes"}

	return config
}
