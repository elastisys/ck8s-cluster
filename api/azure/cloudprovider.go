package azure

import "github.com/elastisys/ck8s/api"

var supportedImages = []*api.Image{
	api.NewImage("ck8s-v1.16.14-ck8s0", "v1.16.14"),
	api.NewImage("ck8s-v1.17.11-ck8s0", "v1.17.11"),
	api.NewImage("ck8s-v1.18.12+ck8s1", "v1.18.12"),
}

var clusterFlavorMap = map[api.ClusterFlavor]func(api.ClusterType, string) api.Cluster{
	FlavorDevelopment: Development,
	FlavorProduction:  Production,
}

type CloudProvider struct{}

func NewCloudProvider() *CloudProvider {
	return &CloudProvider{}
}

func (e *CloudProvider) Type() api.CloudProviderType {
	return api.Azure
}

func (e *CloudProvider) Flavors() (flavors []api.ClusterFlavor) {
	for flavor := range clusterFlavorMap {
		flavors = append(flavors, flavor)
	}
	return
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
	clusterFactory, ok := clusterFlavorMap[flavor]
	if !ok {
		return nil, api.NewUnsupportedClusterFlavorError(api.Azure, flavor)
	}
	return clusterFactory(clusterType, clusterName), nil
}

func (e *CloudProvider) TerraformBackendConfig() *api.TerraformBackendConfig {
	backendConfig := &api.TerraformBackendConfig{
		Hostname:     "app.terraform.io",
		Organization: "",
	}
	backendConfig.Workspaces.Prefix = "ck8s-azure-"
	return backendConfig
}

func (e *CloudProvider) MachineImages(api.NodeType) []*api.Image {
	return supportedImages
}

func (e *CloudProvider) MachineSettings() interface{} {
	return nil
}
