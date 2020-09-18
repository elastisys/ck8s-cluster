package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
)

// Sizes
// Name            RAM      vCPUs
// ------------------------------
// SMALL          2 GB    2 Cores
// MEDIUM         4 GB    2 Cores
// LARGE          8 GB    4 Cores
// EXTRA-LARGE   16 GB    4 Cores
// HUGE          32 GB    8 Cores
// MEGA          64 GB   12 Cores
// TITAN        128 GB   16 Cores
// JUMBO        225 GB   24 Cores

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
			BaseSecret: *api.DefaultBaseSecret(),
			APIKey:     "changeme",
			SecretKey:  "changeme",
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

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		"Small",
	).MustBuild()

	workerExtraLargeSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Extra-large",
	).WithProviderSettings(map[string]interface{}{
		// Match ES_DATA_STORAGE_SIZE in config.sh
		// Note that this value is in GB while config.sh uses Gi
		"es_local_storage_capacity": 12,
	}).MustBuild()

	workerLargeSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Large",
	).WithProviderSettings(map[string]interface{}{
		// Match ES_DATA_STORAGE_SIZE in config.sh
		// Note that this value is in GB while config.sh uses Gi
		"es_local_storage_capacity": 12,
	}).MustBuild()

	workerWC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Large",
	).MustBuild()

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerExtraLargeSC,
		"worker-1": workerLargeSC,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerWC,
	}

	cluster.tfvars.NFSSize = "Small"

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	// TODO:
	// - Safespring has 8 cores for the "extra-large" but here we have only 4
	// - How many nodes with local storage do we need?

	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		"Medium",
	).MustBuild()

	workerExtraLargeSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Extra-large",
	).MustBuild()

	workerLargeESSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Large",
	).WithProviderSettings(map[string]interface{}{
		// Match ES_DATA_STORAGE_SIZE in config.sh
		// Note that this value is in GB while config.sh uses Gi
		"es_local_storage_capacity": 140,
	}).MustBuild()

	workerLargeSC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Large",
	).MustBuild()

	workerWC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"Large",
	).MustBuild()

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"master-1": master,
		"master-2": master,
		"worker-0": workerExtraLargeSC,
		"worker-1": workerLargeESSC,
		"worker-2": workerLargeESSC,
		"worker-3": workerLargeSC,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0":      master,
		"master-1":      master,
		"master-2":      master,
		"worker-ck8s-0": workerWC,
		"worker-0":      workerWC,
		"worker-1":      workerWC,
		"worker-2":      workerWC,
	}

	cluster.tfvars.NFSSize = "Small"

	return cluster
}
