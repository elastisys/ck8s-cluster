package api

import "fmt"

type CloudProviderType string

const (
	AWS        CloudProviderType = "aws"
	CityCloud  CloudProviderType = "citycloud"
	Exoscale   CloudProviderType = "exoscale"
	Safespring CloudProviderType = "safespring"
)

type ClusterFlavor string

type CloudProvider interface {
	// Flavors should return a list of cluster flavors.
	Flavors() []ClusterFlavor
	// Default should return a cluster with only the default configuration set.
	Default(ClusterType, string) Cluster
	// Cluster should return a preconfigured cluster depending on flavor.
	Cluster(ClusterType, ClusterFlavor, string) (Cluster, error)
	// TerraformBackendConfig should return the default backend config.
	TerraformBackendConfig() *TerraformBackendConfig
}

type ClusterStateLoadFunc func(interface{}) error

type Cluster interface {
	Config() interface{}
	Secret() interface{}
	TFVars() interface{}

	// TODO: We should be able to combine these if we only handled a single
	// 		 cluster and deprecated the prefixes in tfvars.
	Name() string
	TerraformWorkspace() string

	CloudProvider() CloudProviderType
	CloudProviderVars(ClusterState) interface{}

	CloneMachine(NodeType, string) (string, error)

	RemoveMachine(NodeType, string) error

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

	Machines() []MachineState

	Machine(NodeType, string) (MachineState, error)
}

type MachineState struct {
	NodeType  NodeType
	Name      string
	PublicIP  string
	PrivateIP string
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

type NodeType int

const (
	Master NodeType = iota
	Worker
	LoadBalancer
)

func (n NodeType) String() string {
	switch n {
	case Master:
		return "master"
	case Worker:
		return "worker"
	case LoadBalancer:
		return "loadbalancer"
	}

	panic(fmt.Sprintf("missing string implementation for node type %d", n))
}

func NodeTypeFromString(s string) NodeType {
	switch s {
	case Master.String():
		return Master
	case Worker.String():
		return Worker
	case LoadBalancer.String():
		return LoadBalancer
	}
	// TODO: return error?
	panic("unknown node type")
}

type TerraformBackendConfig struct {
	Hostname     string `hcl:"hostname"`
	Organization string `hcl:"organization"`
	Workspaces   struct {
		Prefix string `hcl:"prefix"`
	} `hcl:"workspaces,block"`
}
