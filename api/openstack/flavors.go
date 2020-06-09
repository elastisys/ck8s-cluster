package openstack

import (
	"github.com/elastisys/ck8s/api"
)

// Empty TODO
func Empty(clusterType api.ClusterType) *Cluster {
	return &Cluster{
		OpenstackConfig: OpenstackConfig{
			BaseConfig: api.EmptyBaseConfig(clusterType, api.Openstack),
		},
		OpenstackSecret: OpenstackSecret{
			BaseSecret: api.BaseSecret{},
		},
		OpenstackTFVars: OpenstackTFVars{},
	}
}

// Default TODO
func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	cluster := Empty(clusterType)

	cluster.EnvironmentName = clusterName

	cluster.DNSPrefix = clusterName

	cluster.S3AccessKey = "changeme"
	cluster.S3SecretKey = "changeme"
	cluster.S3RegionAddress = "changeme"

	cluster.S3BucketNameHarbor = clusterName + "-harbor"
	cluster.S3BucketNameVelero = clusterName + "-velero"
	cluster.S3BucketNameElasticsearch = clusterName + "-es-backup"
	cluster.S3BucketNameInfluxDB = clusterName + "-influxdb"
	cluster.S3BucketNameFluentd = clusterName + "-sc-logs"

	cluster.PublicIngressCIDRWhitelist = []string{}
	cluster.APIServerWhitelist = []string{}

	return cluster
}
