package citycloud

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
		},
	}
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
