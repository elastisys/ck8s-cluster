package safespring

import (
	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

// Cluster TODO
type Cluster struct {
	openstack.Cluster `mapstructure:",squash"`
}

// State TODO
func (e *Cluster) State(
	loadState api.ClusterStateLoadFunc,
) (api.ClusterState, error) {
	tfOutput := openstack.DefaultState(&e.Cluster)

	return &tfOutput, loadState(&tfOutput)
}
