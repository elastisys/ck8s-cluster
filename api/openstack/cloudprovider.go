package openstack

import "github.com/elastisys/ck8s/api"

type CloudProvider struct{}

func NewCloudProvider() *CloudProvider {
	return &CloudProvider{}
}

func (e *CloudProvider) Flavors() []api.ClusterFlavor {
	return make([]api.ClusterFlavor, 0)
}

func (e *CloudProvider) Default(
	clusterType api.ClusterType,
	clusterName string,
) api.Cluster {
	return Default(clusterType, clusterName)
}

func (e *CloudProvider) Cluster(
	clusterType api.ClusterType,
	flavor api.ClusterFlavor,
	clusterName string,
) (api.Cluster, error) {
	return nil, api.NewUnsupportedClusterFlavorError(api.Openstack, flavor)
}
