package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
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
			NodeportWhitelist:          []string{},
		},
	}
}

func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cluster.tfvars.MasterNamesSC = []string{"master-0"}
	cluster.tfvars.MasterNameSizeMapSC = map[string]string{"master-0": "Small"}

	cluster.tfvars.WorkerNamesSC = []string{"worker-0", "worker-1"}
	cluster.tfvars.WorkerNameSizeMapSC = map[string]string{
		"worker-0": "Extra-large",
		"worker-1": "Large",
	}
	cluster.tfvars.ESLocalStorageCapacityMapSC = map[string]int{
		"worker-0": 26,
		"worker-1": 26,
	}

	cluster.tfvars.MasterNamesWC = []string{"master-0"}
	cluster.tfvars.MasterNameSizeMapWC = map[string]string{"master-0": "Small"}

	cluster.tfvars.WorkerNamesWC = []string{"worker-0"}
	cluster.tfvars.WorkerNameSizeMapWC = map[string]string{"worker-0": "Large"}

	cluster.tfvars.ESLocalStorageCapacityMapWC = map[string]int{"worker-0": 0}

	cluster.tfvars.NFSSize = "Small"

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
