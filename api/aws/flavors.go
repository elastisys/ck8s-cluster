package aws

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorDevelopment api.ClusterFlavor = "dev"
	FlavorProduction  api.ClusterFlavor = "prod"
)

func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	return &Cluster{
		config: AWSConfig{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				api.AWS,
				clusterName,
			),
			S3Region: "us-west-1",
		},
		secret: AWSSecret{
			BaseSecret: api.BaseSecret{
				S3AccessKey: "changeme",
				S3SecretKey: "changeme",
			},
			AWSAccessKeyID:     "changeme",
			AWSSecretAccessKey: "changeme",
			DNSAccessKeyID:     "changeme",
			DNSSecretAccessKey: "changeme",
		},
		tfvars: AWSTFVars{
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
		"t3.small",
	).MustBuild()
	workerExtraLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"t3.xlarge",
	).MustBuild()
	workerLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"t3.large",
	).MustBuild()

	cluster.tfvars.Region = "us-west-1"

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerExtraLarge,
		"worker-1": workerLarge,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0": master,
		"worker-0": workerLarge,
		// TODO Should we use two nodes here?
		"worker-1": workerLarge,
	}

	return cluster
}

func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	// TODO:
	// - Safespring has 8 cores for the "extra-large" and 4 for "large"
	//   but here we have only 4 and 2 respectivly.
	// - Maybe we should switch to non-burstable instances?

	cluster := Default(clusterType, clusterName)

	cloudProvider := NewCloudProvider()

	master := api.NewMachineFactory(
		cloudProvider,
		api.Master,
		"t3.small",
	).MustBuild()
	workerExtraLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"t3.xlarge",
	).MustBuild()
	workerLarge := api.NewMachineFactory(
		cloudProvider,
		api.Worker,
		"t3.large",
	).MustBuild()

	cluster.tfvars.Region = "us-west-1"

	cluster.tfvars.MachinesSC = map[string]*api.Machine{
		"master-0": master,
		"master-1": master,
		"master-2": master,
		"worker-0": workerExtraLarge,
		"worker-1": workerLarge,
		"worker-2": workerLarge,
		"worker-3": workerLarge,
	}

	cluster.tfvars.MachinesWC = map[string]*api.Machine{
		"master-0":      master,
		"master-1":      master,
		"master-2":      master,
		"worker-ck8s-0": workerLarge,
		"worker-0":      workerLarge,
		"worker-1":      workerLarge,
		"worker-2":      workerLarge,
	}

	return cluster
}
