package exoscale

import "github.com/elastisys/ck8s/api"

var supportedImages = []string{
	"CK8S BaseOS v0.0.6",
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
	return api.Exoscale
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
		return nil, api.NewUnsupportedClusterFlavorError(api.Exoscale, flavor)
	}
	return clusterFactory(clusterType, clusterName), nil
}

func (e *CloudProvider) TerraformBackendConfig() *api.TerraformBackendConfig {
	backendConfig := &api.TerraformBackendConfig{
		Hostname:     "app.terraform.io",
		Organization: "",
	}
	backendConfig.Workspaces.Prefix = "ck8s-exoscale-"
	return backendConfig
}

func (e *CloudProvider) MachineImages(api.NodeType) []string {
	return supportedImages
}

func (e *CloudProvider) MachineSettings() interface{} {
	return &MachineSettings{}
}
