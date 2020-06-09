package exoscale

import (
	"github.com/elastisys/ck8s/api"
)

const (
	FlavorMinimum api.ClusterFlavor = "minimum"
	FlavorHA      api.ClusterFlavor = "ha"
)

func Empty(clusterType api.ClusterType) *Cluster {
	return &Cluster{
		ExoscaleConfig: ExoscaleConfig{
			BaseConfig: api.EmptyBaseConfig(clusterType),
		},
		ExoscaleSecret: ExoscaleSecret{
			BaseSecret: api.BaseSecret{},
		},
		ExoscaleTFVars: ExoscaleTFVars{},
	}
}

func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	cluster := Empty(clusterType)

	cluster.CloudProviderType = api.Exoscale

	cluster.EnvironmentName = clusterName

	cluster.DNSPrefix = clusterName

	cluster.APIKey = "changeme"
	cluster.SecretKey = "changeme"

	cluster.S3AccessKey = "changeme"
	cluster.S3SecretKey = "changeme"
	cluster.S3RegionAddress = "sos-ch-gva-2.exo.io"

	cluster.S3BucketNameHarbor = clusterName + "-harbor"
	cluster.S3BucketNameVelero = clusterName + "-velero"
	cluster.S3BucketNameElasticsearch = clusterName + "-es-backup"
	cluster.S3BucketNameInfluxDB = clusterName + "-influxdb"
	cluster.S3BucketNameFluentd = clusterName + "-sc-logs"

	cluster.PublicIngressCIDRWhitelist = []string{}
	cluster.APIServerWhitelist = []string{}

	return cluster
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
