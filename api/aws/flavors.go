package aws

import (
	"github.com/elastisys/ck8s/api"
)

const (
	// FlavorDevelopment TODO
	FlavorDevelopment api.ClusterFlavor = "dev"

	// FlavorProduction TODO
	FlavorProduction api.ClusterFlavor = "prod"
)

// Default TODO
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
		},
	}
}

// Development TODO
func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cluster.tfvars.Region = "us-west-1"

	cluster.tfvars.MasterNodesSC = map[string]string{
		"master-0": "t3.small",
	}

	cluster.tfvars.WorkerNodesSC = map[string]string{
		"worker-0": "t3.xlarge",
		"worker-1": "t3.large",
	}

	cluster.tfvars.MasterNodesWC = map[string]string{
		"master-0": "t3.small",
	}

	// TODO Should we use two nodes here?
	cluster.tfvars.WorkerNodesWC = map[string]string{
		"worker-0": "t3.large",
		"worker-1": "t3.large",
	}

	return cluster
}

// Production TODO
func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
