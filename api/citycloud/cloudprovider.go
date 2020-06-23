package citycloud

import (
	"github.com/elastisys/ck8s/api"
)

var clusterFlavorMap = map[api.ClusterFlavor]func(api.ClusterType, string) api.Cluster{
	FlavorDevelopment: Development,
	FlavorProduction:  Production,
}

// CloudProvider TODO
type CloudProvider struct{}

// NewCloudProvider TODO
func NewCloudProvider() *CloudProvider {
	return &CloudProvider{}
}

// Flavors TODO
func (e *CloudProvider) Flavors() (flavors []api.ClusterFlavor) {
	for flavor := range clusterFlavorMap {
		flavors = append(flavors, flavor)
	}
	return
}

// Default TODO
func (e *CloudProvider) Default(
	clusterType api.ClusterType,
	clusterName string,
) api.Cluster {
	return Default(clusterType, clusterName)
}

// Cluster TODO
func (e *CloudProvider) Cluster(
	clusterType api.ClusterType,
	flavor api.ClusterFlavor,
	clusterName string,
) (api.Cluster, error) {
	clusterFactory, ok := clusterFlavorMap[flavor]
	if !ok {
		return nil, api.NewUnsupportedClusterFlavorError(api.CityCloud, flavor)
	}
	return clusterFactory(clusterType, clusterName), nil
}

func (e *CloudProvider) TerraformBackendConfig() *api.TerraformBackendConfig {
	backendConfig := &api.TerraformBackendConfig{
		Hostname:     "app.terraform.io",
		Organization: "elastisys",
	}
	backendConfig.Workspaces.Prefix = "ck8s-citycloud-"
	return backendConfig
}
