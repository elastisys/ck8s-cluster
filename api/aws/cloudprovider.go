package aws

import "github.com/elastisys/ck8s/api"

var supportedImages = map[string][]string{
	"us-west-1": {
		"ami-025fd2f1456a0e2e5",
	},
}

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
	return api.AWS
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
		return nil, api.NewUnsupportedClusterFlavorError(api.AWS, flavor)
	}
	return clusterFactory(clusterType, clusterName), nil
}

// TerraformBackendConfig TODO
func (e *CloudProvider) TerraformBackendConfig() *api.TerraformBackendConfig {
	backendConfig := &api.TerraformBackendConfig{
		Hostname:     "app.terraform.io",
		Organization: "",
	}
	backendConfig.Workspaces.Prefix = "ck8s-aws-"
	return backendConfig
}

func (e *CloudProvider) MachineImages(api.NodeType) []string {
	// TODO: Add support for multiple regions.
	return supportedImages["us-west-1"]
}

func (e *CloudProvider) MachineSettings() interface{} {
	return nil
}
