package citycloud

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
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
		config: openstack.OpenstackConfig{
			BaseConfig: *api.DefaultBaseConfig(
				clusterType,
				api.CityCloud,
				clusterName,
			),
			S3RegionAddress: "swift-fra1.citycloud.com:8080",
		},
		secret: openstack.OpenstackSecret{
			BaseSecret: api.BaseSecret{
				S3AccessKey: "changeme",
				S3SecretKey: "changeme",
			},
		},
		tfvars: openstack.OpenstackTFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},

			ExternalNetworkID:   "71b10496-2617-47ae-abbc-36239f0863bb",
			ExternalNetworkName: "public-v4",

			// TODO: We need to get rid of these.
			AWSDNSZoneID:  "Z2STJRQSJO5PZ0", // elastisys.se
			AWSDNSRoleARN: "arn:aws:iam::248119176842:role/a1-pipeline",
		},
	}
}

// Development TODO
func Development(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	cluster.tfvars.MasterNamesSC = []string{"master-0"}
	cluster.tfvars.MasterNameSizeMapSC = map[string]string{
		"master-0": "89afeed0-9e41-4091-af73-727298a5d959", // 2 Core 4gb mem 50gb storage
	}

	cluster.tfvars.WorkerNamesSC = []string{"worker-0", "worker-1"}
	cluster.tfvars.WorkerNameSizeMapSC = map[string]string{
		"worker-0": "f6a5e4d3-203d-45c0-a36a-dc5538580e1a", // 4 core 16gb mem 50gb storage
		"worker-1": "ecd976c3-c71c-4096-b138-e4d964c0b27f", // 4 core 8gb mem 50gb storage
	}
	cluster.tfvars.MasterNamesWC = []string{"master-0"}
	cluster.tfvars.MasterNameSizeMapWC = map[string]string{
		"master-0": "89afeed0-9e41-4091-af73-727298a5d959", // 2 core 4gb mem 50gb storage
	}

	cluster.tfvars.WorkerNamesWC = []string{"worker-0"}
	cluster.tfvars.WorkerNameSizeMapWC = map[string]string{
		"worker-0": "ecd976c3-c71c-4096-b138-e4d964c0b27f", // 4 core 8gb mem 50gb storage
	}

	cluster.tfvars.MasterAntiAffinityPolicySC = "anti-affinity"
	cluster.tfvars.MasterAntiAffinityPolicyWC = "anti-affinity"

	return cluster
}

// Production TODO
func Production(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
