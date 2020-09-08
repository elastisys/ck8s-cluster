package azure

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
)

func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	return &Cluster{
		config: AzureConfig{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				api.Azure,
				clusterName,
			),
			// TODO change this to azure storage
			S3RegionAddress: "sos-ch-gva-2.exo.io",
		},
		secret: AzureSecret{
			BaseSecret: *api.DefaultBaseSecret(),
			APIKey:     "changeme",
			SecretKey:  "changeme",
		},
		tfvars: AzureTFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},
			NodeportWhitelist:          []string{},
			SubscriptionID:             "changeme",
			TennantID:                  "changeme",
		},
	}
}

func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cluster.tfvars.MachinesSC = map[string]api.Machine{
		"master-0": {
			NodeType: api.Master,
			Size:     "TODO-Small",
		},
		"worker-0": {
			NodeType: api.Worker,
			Size:     "TODO-Extra-large",
		},
		"worker-1": {
			NodeType: api.Worker,
			Size:     "TODO-Large",
		},
	}

	cluster.tfvars.MachinesWC = map[string]api.Machine{
		"master-0": {
			NodeType: api.Master,
			Size:     "TODO-Small",
		},
		"worker-0": {
			NodeType: api.Worker,
			Size:     "TODO-Large",
		},
	}

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
