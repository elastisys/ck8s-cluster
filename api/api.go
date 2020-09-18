package api

type CloudProviderType string

const (
	AWS        CloudProviderType = "aws"
	CityCloud  CloudProviderType = "citycloud"
	Exoscale   CloudProviderType = "exoscale"
	Safespring CloudProviderType = "safespring"
)

type ClusterFlavor string

type CloudProvider interface {
	// Type should return the cloud provider type.
	Type() CloudProviderType
	// Flavors should return a list of cluster flavors.
	Flavors() []ClusterFlavor
	// Default should return a cluster with only the default configuration set.
	Default(ClusterType, string) Cluster
	// Cluster should return a preconfigured cluster depending on flavor.
	Cluster(ClusterType, ClusterFlavor, string) (Cluster, error)
	// TerraformBackendConfig should return the default backend config.
	TerraformBackendConfig() *TerraformBackendConfig
	// MachineImages should return a slice with the machine images that the
	// provider supports. The images should be sorted from oldest to latest
	// version.
	MachineImages(NodeType) []string
	// MachineSettings should return a provider specific machine settings
	// struct.
	MachineSettings() interface{}
}

type ClusterStateLoadFunc func(interface{}) error

type Cluster interface {
	Config() interface{}
	Secret() interface{}
	TFVars() interface{}

	Machines() map[string]*Machine

	// TODO: We should be able to combine these if we only handled a single
	// 		 cluster and deprecated the prefixes in tfvars.
	Name() string
	TerraformWorkspace() string

	CloudProvider() CloudProviderType
	CloudProviderVars(ClusterState) interface{}

	AddMachine(string, *Machine) (string, error)
	RemoveMachine(string) error

	// TODO: We should try to get rid of this.
	TerraformEnv(sshPublicKey string) map[string]string

	AnsibleEnv() map[string]string

	State(ClusterStateLoadFunc) (ClusterState, error)

	S3Buckets() map[string]string
}

type ClusterState interface {
	ControlPlanePublicIP() string
	ControlPlaneEndpoint() string

	BaseDomain() string

	Machines() map[string]MachineState

	Machine(string) (MachineState, error)
}

type ClusterType int

const (
	ServiceCluster ClusterType = iota + 1
	WorkloadCluster
)

func (c ClusterType) String() string {
	switch c {
	case ServiceCluster:
		return "sc"
	case WorkloadCluster:
		return "wc"
	default:
		return "unknown"
	}
}

type TerraformBackendConfig struct {
	Hostname     string `hcl:"hostname"`
	Organization string `hcl:"organization"`
	Workspaces   struct {
		Prefix string `hcl:"prefix"`
	} `hcl:"workspaces,block"`
}
