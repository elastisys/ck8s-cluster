package safespring

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

// Cluster TODO
type Cluster struct {
	*openstack.Cluster
}

// Config TODO
func (e *Cluster) Config() interface{} {
	return &e.Cluster.Config
}

// Secret TODO
func (e *Cluster) Secret() interface{} {
	return &e.Cluster.Secret
}

// TFVars TODO
func (e *Cluster) TFVars() interface{} {
	return &e.Cluster.TFVars
}

func (e *Cluster) CloudProviderVars(state api.ClusterState) interface{} {
	return nil
}

// State TODO
func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := terraformOutput{
		TerraformOutput: openstack.StateHelper(
			e.Cluster.Config.ClusterType,
			e.Name(),
		),
	}

	return &tfOutput, loadState(&tfOutput)
}
