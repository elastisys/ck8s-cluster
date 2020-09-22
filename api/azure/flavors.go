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

			TenantID:       "changeme",
			SubscriptionID: "changeme",
			Location:       "changeme",
		},
		secret: AzureSecret{
			BaseSecret:   *api.DefaultBaseSecret(),
			ClientID:     "changeme",
			ClientSecret: "changeme",
		},
		tfvars: AzureTFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},
			NodeportWhitelist:          []string{},
		},
	}
}

func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		// 2C-8GB-50GB
		"Standard_D2_v3",
	).MustBuild()

	workerLargeSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-16GB-50GB
		"Standard_D4_v3",
	).MustBuild()

	workerLargeWC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-16GB-50GB
		"Standard_D4_v3",
	).MustBuild()

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerLargeSC,
		"worker-1": workerLargeSC,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerLargeWC,
	}

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
