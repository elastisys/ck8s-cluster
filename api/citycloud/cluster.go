package citycloud

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

// Cluster TODO
type Cluster struct {
	*openstack.Cluster
}

type cloudProviderVars struct {
	LBEnabled           bool   `json:"lb_enabled"`
	LBExternalNetworkID string `json:"lb_external_network_id"`
	LBSubnetID          string `json:"lb_subnet_id"`
	SecurityGroupID     string `json:"secgroup_id"`
	UseOctavia          bool   `json:"use_octavia"`
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

func (e *Cluster) CloudProviderVars(state api.ClusterState) interface{} {
	cityCloudState, ok := state.(*terraformOutput)
	if !ok {
		panic("wrong CityCloud state type")
	}

	cpv := &cloudProviderVars{
		LBEnabled:           true,
		LBExternalNetworkID: e.Cluster.TFVars.ExternalNetworkID,
		UseOctavia:          true,
	}

	switch e.Cluster.Config.ClusterType {
	case api.ServiceCluster:
		cpv.LBSubnetID = cityCloudState.SCLBSubnetID.Value
		cpv.SecurityGroupID = cityCloudState.SCSecurityGroupID.Value
	case api.WorkloadCluster:
		cpv.LBSubnetID = cityCloudState.WCLBSubnetID.Value
		cpv.SecurityGroupID = cityCloudState.WCSecurityGroupID.Value
	default:
		panic(fmt.Sprintf(
			"invalid cluster type: %s",
			e.Cluster.Config.ClusterType,
		))
	}

	return cpv
}
