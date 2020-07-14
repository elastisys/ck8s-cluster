package aws

import (
	"fmt"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

// AWSTFVars TODO
type AWSTFVars struct {
	Region string `hcl:"region"`

	PrefixSC string `hcl:"prefix_sc"`
	PrefixWC string `hcl:"prefix_wc"`

	MasterNodesSC map[string]string `hcl:"master_nodes_sc" validate:"required,min=1"`
	WorkerNodesSC map[string]string `hcl:"worker_nodes_sc"`
	MasterNodesWC map[string]string `hcl:"master_nodes_wc" validate:"required,min=1"`
	WorkerNodesWC map[string]string `hcl:"worker_nodes_wc" validate:"required"`

	PublicIngressCIDRWhitelist []string `hcl:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `hcl:"api_server_whitelist" validate:"required"`
	NodeportWhitelist  []string `hcl:"nodeport_whitelist" validate:"required"`
}

func (e *Cluster) Machines() (machines []api.Machine) {
	for _, nodeType := range []api.NodeType{
		api.Master,
		api.Worker,
	} {
		part := e.lookupMachinePart(e.config.ClusterType, nodeType)
		for name := range part.nameSizeMap {
			machines = append(machines, api.Machine{
				Name:     name,
				NodeType: nodeType,
			})
		}
	}
	return
}

// CloneMachine TODO
func (e *Cluster) CloneMachine(
	nodeType api.NodeType,
	name string,
) (string, error) {
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

	cloneName := uuid.New().String()

	size, ok := part.nameSizeMap[name]
	if !ok {
		return "", fmt.Errorf("machine not found: %s", name)
	}

	part.nameSizeMap[cloneName] = size

	return cloneName, nil
}

// RemoveMachine TODO
func (e *Cluster) RemoveMachine(
	nodeType api.NodeType,
	name string,
) error {
	// TODO: When we no longer need ClusterType these methods could be
	//		 implemented directly on the TFVars struct.
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

	delete(part.nameSizeMap, name)

	return nil
}

type tfvarsMachinePart struct {
	nameSizeMap map[string]string
}

func (e *Cluster) lookupMachinePart(
	cluster api.ClusterType,
	nodeType api.NodeType,
) tfvarsMachinePart {
	return map[api.ClusterType]map[api.NodeType]tfvarsMachinePart{
		api.ServiceCluster: {
			api.Master: {
				e.tfvars.MasterNodesSC,
			},
			api.Worker: {
				e.tfvars.WorkerNodesSC,
			},
		},
		api.WorkloadCluster: {
			api.Master: {
				e.tfvars.MasterNodesWC,
			},
			api.Worker: {
				e.tfvars.WorkerNodesWC,
			},
		},
	}[cluster][nodeType]
}
