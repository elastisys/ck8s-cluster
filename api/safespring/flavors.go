package safespring

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
				api.Safespring,
				clusterName,
			),

			IdentityAPIVersion: "3",
			AuthURL:            "https://keystone.api.cloud.ipnett.se/v3",
			RegionName:         "se-east-1",

			ProjectID:         "changeme",
			ProjectDomainName: "changeme",
			UserDomainName:    "changeme",

			S3RegionAddress: "s3.sto1.safedc.net",
		},
		secret: openstack.OpenstackSecret{},
		tfvars: SafespringTFVars{
			PublicIngressCIDRWhitelist: []string{},
			APIServerWhitelist:         []string{},
			NodeportWhitelist:          []string{},

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
		// TODO: could go with smaller flavor here if made available
		"master-0": "dc67a9eb-0685-4bb6-9383-a01c717e02e8", // lb.large.1d
	}

	cluster.tfvars.WorkerNamesSC = []string{"worker-0", "worker-1"}
	cluster.tfvars.WorkerNameSizeMapSC = map[string]string{
		"worker-0": "ea0dbe3b-f93a-47e0-84e4-b09ec5873bdf", // lb.xlarge.1d
		"worker-1": "dc67a9eb-0685-4bb6-9383-a01c717e02e8", // lb.large.1d
	}

	cluster.tfvars.MasterNamesWC = []string{"master-0"}
	cluster.tfvars.MasterNameSizeMapWC = map[string]string{
		// TODO: could go with smaller flavor here if made available
		"master-0": "dc67a9eb-0685-4bb6-9383-a01c717e02e8", // lb.large.1d
	}

	cluster.tfvars.WorkerNamesWC = []string{"worker-0"}
	cluster.tfvars.WorkerNameSizeMapWC = map[string]string{
		"worker-0": "dc67a9eb-0685-4bb6-9383-a01c717e02e8", // lb.large.1d
	}

	cluster.tfvars.LoadBalancerNamesSC = []string{"loadbalancer-0"}
	cluster.tfvars.LoadBalancerNameFlavorMapSC = map[string]string{
		"loadbalancer-0": "51d480b8-2517-4ba8-bfe0-c649ac93eb61", // lb.tiny
	}

	cluster.tfvars.LoadBalancerNamesWC = []string{"loadbalancer-0"}
	cluster.tfvars.LoadBalancerNameFlavorMapWC = map[string]string{
		"loadbalancer-0": "51d480b8-2517-4ba8-bfe0-c649ac93eb61", // lb.tiny
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
