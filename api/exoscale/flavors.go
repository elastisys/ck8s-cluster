package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorMinimum api.ClusterFlavor = "minimum"
	FlavorHA      api.ClusterFlavor = "ha"
)

func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	return &Cluster{
		config: ExoscaleConfig{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				api.Exoscale,
				clusterName,
			),
			S3RegionAddress: "sos-ch-gva-2.exo.io",
		},
		secret: ExoscaleSecret{
			BaseSecret: api.BaseSecret{
				S3AccessKey: "changeme",
				S3SecretKey: "changeme",
			},
			APIKey:    "changeme",
			SecretKey: "changeme",
		},
		tfvars: ExoscaleTFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},
		},
	}
}

func Minimum(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}

func HA(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
