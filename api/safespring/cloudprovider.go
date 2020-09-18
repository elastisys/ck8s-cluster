package safespring

import (
	"github.com/elastisys/ck8s/api"
)

var (
	supportedCK8SBaseOSImages = []*api.Image{
		api.NewImage("CK8S BaseOS v0.0.6", "v1.15.11"),
	}

	supportedImages = map[api.NodeType][]*api.Image{
		api.Master: supportedCK8SBaseOSImages,
		api.Worker: supportedCK8SBaseOSImages,
		api.LoadBalancer: {
			api.NewImage("ubuntu-18.04-server-cloudimg-amd64-20190212.1", ""),
		},
	}
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

func (e *CloudProvider) Type() api.CloudProviderType {
	return api.Safespring
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
		return nil, api.NewUnsupportedClusterFlavorError(api.Safespring, flavor)
	}
	return clusterFactory(clusterType, clusterName), nil
}

func (e *CloudProvider) TerraformBackendConfig() *api.TerraformBackendConfig {
	backendConfig := &api.TerraformBackendConfig{
		Hostname:     "app.terraform.io",
		Organization: "",
	}
	backendConfig.Workspaces.Prefix = "ck8s-safespring-"
	return backendConfig
}

func (e *CloudProvider) MachineImages(nodeType api.NodeType) []*api.Image {
	return supportedImages[nodeType]
}

func (e *CloudProvider) MachineSettings() interface{} {
	return nil
}
