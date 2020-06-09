package safespring

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

const (
	// FlavorMinimum TODO
	FlavorMinimum api.ClusterFlavor = "minimum"

	// FlavorHA TODO
	FlavorHA api.ClusterFlavor = "ha"
)

// Empty TODO
func Empty(clusterType api.ClusterType) *Cluster {
	cluster := &Cluster{
		*openstack.Empty(clusterType),
	}

	cluster.CloudProviderType = api.Safespring

	return cluster
}

// Default TODO
func Default(clusterType api.ClusterType, clusterName string) *Cluster {
	cluster := &Cluster{
		*openstack.Default(clusterType, clusterName),
	}

	cluster.CloudProviderType = api.Safespring

	cluster.S3RegionAddress = "s3.sto1.safedc.net"

	return cluster
}

// Minimum TODO
func Minimum(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}

// HA TODO
func HA(clusterType api.ClusterType, clusterName string) api.Cluster {
	cluster := Default(clusterType, clusterName)

	// TODO

	return cluster
}
