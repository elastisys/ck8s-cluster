package azure

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
)

// Common sizes:
// More details here: https://docs.microsoft.com/en-us/azure/virtual-machines/dv2-dsv2-series
// +-----------------+------+-----------+------------+----------------+----------+
// | Size            | vCPU | RAM (GiB) | Disk (GiB) | Max data disks | Max NICs |
// +-----------------+------+-----------+------------+----------------+----------+
// | Standard_D2_v3  | 2    | 8         | 50         | 4              | 2        |
// | Standard_D4_v3  | 4    | 16        | 100        | 8              | 2        |
// | Standard_D8_v3  | 8    | 32        | 200        | 16             | 4        |
// | Standard_D16_v3 | 16   | 64        | 400        | 32             | 8        |
// | Standard_D32_v3 | 32   | 128       | 800        | 32             | 8        |
// | Standard_D48_v3 | 48   | 192       | 1200       | 32             | 8        |
// | Standard_D64_v3 | 64   | 256       | 1600       | 32             | 8        |
// +-----------------+------+-----------+------------+----------------+----------+

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
		// 4C-16GB-100GB
		"Standard_D4_v3",
	).MustBuild()

	workerLargeWC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-16GB-100GB
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
		// 4C-16GB-100GB
		"Standard_D4_v3",
	).MustBuild()

	workerLargeWC := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		// 4C-16GB-100GB
		"Standard_D4_v3",
	).MustBuild()

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"master-1": master,
		"master-2": master,
		"worker-0": workerLargeSC,
		"worker-1": workerLargeSC,
		"worker-2": workerLargeSC,
		"worker-3": workerLargeSC,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0":      master,
		"master-1":      master,
		"master-2":      master,
		"worker-ck8s-0": workerLargeWC,
		"worker-0":      workerLargeWC,
		"worker-1":      workerLargeWC,
		"worker-2":      workerLargeWC,
	}

	return cluster
}
