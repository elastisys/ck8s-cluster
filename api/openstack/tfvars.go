package openstack

import (
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

type OpenstackTFVars struct {
	PrefixSC string `hcl:"prefix_sc"`
	PrefixWC string `hcl:"prefix_wc"`

	// TODO: Combine these
	MasterNamesSC       []string          `hcl:"master_names_sc" validate:"required,min=1"`
	MasterNameSizeMapSC map[string]string `hcl:"master_name_flavor_map_sc" validate:"required"`

	// TODO: Combine these
	WorkerNamesSC       []string          `hcl:"worker_names_sc"`
	WorkerNameSizeMapSC map[string]string `hcl:"worker_name_flavor_map_sc"`

	// TODO: Combine these
	MasterNamesWC       []string          `hcl:"master_names_wc" validate:"required,min=1"`
	MasterNameSizeMapWC map[string]string `hcl:"master_name_flavor_map_wc" validate:"required"`

	// TODO: Combine these
	WorkerNamesWC       []string          `hcl:"worker_names_wc" validate:"required"`
	WorkerNameSizeMapWC map[string]string `hcl:"worker_name_flavor_map_wc" validate:"required"`

	// TODO: Combine these
	LoadBalancerNamesSC         []string          `hcl:"loadbalancer_names_sc" validate:"required"`
	LoadBalancerNameFlavorMapSC map[string]string `hcl:"loadbalancer_name_flavor_map_sc" validate:"required"`

	// TODO: Combine these
	LoadBalancerNamesWC         []string          `hcl:"loadbalancer_names_wc" validate:"required"`
	LoadBalancerNameFlavorMapWC map[string]string `hcl:"loadbalancer_name_flavor_map_wc" validate:"required"`

	PublicIngressCIDRWhitelist []string `hcl:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `hcl:"api_server_whitelist" validate:"required"`

	AWSDNSZoneID  string `hcl:"aws_dns_zone_id" validate:"required"`
	AWSDNSRoleARN string `hcl:"aws_dns_role_arn" validate:"required"`

	ExternalNetworkID   string `hcl:"external_network_id" validate:"required"`
	ExternalNetworkName string `hcl:"external_network_name" validate:"required"`
}

func (e *Cluster) CloneMachine(
	nodeType api.NodeType,
	name string,
) (string, error) {
	part := e.lookupMachinePart(e.ClusterType, nodeType)

	// TODO Find the root cause for this issue
	cloneName := strings.Replace(uuid.New().String(), "-", "", -1)

	size, ok := part.sizeMap[name]
	if !ok {
		return "", fmt.Errorf("machine not found: %s", name)
	}

	*part.nameSlice = append(*part.nameSlice, cloneName)
	part.sizeMap[cloneName] = size

	return cloneName, nil
}

func (e *Cluster) RemoveMachine(
	nodeType api.NodeType,
	name string,
) error {
	part := e.lookupMachinePart(e.ClusterType, nodeType)

	_, ok := part.sizeMap[name]
	if !ok {
		return fmt.Errorf("machine not found: %s", name)
	}

	for i, n := range *part.nameSlice {
		if n == name {
			*part.nameSlice = append(
				(*part.nameSlice)[:i],
				(*part.nameSlice)[i+1:]...,
			)
			break
		}
	}

	delete(part.sizeMap, name)

	return nil
}

type tfvarsMachinePart struct {
	nameSlice *[]string
	sizeMap   map[string]string
}

func (e *Cluster) lookupMachinePart(
	cluster api.ClusterType,
	nodeType api.NodeType,

) tfvarsMachinePart {
	return map[api.ClusterType]map[api.NodeType]tfvarsMachinePart{
		api.ServiceCluster: {
			api.Master: {
				&e.OpenstackTFVars.MasterNamesSC,
				e.OpenstackTFVars.MasterNameSizeMapSC,
			},
			api.Worker: {
				&e.OpenstackTFVars.WorkerNamesSC,
				e.OpenstackTFVars.WorkerNameSizeMapSC,
			},
			api.LoadBalancer: {
				&e.OpenstackTFVars.LoadBalancerNamesSC,
				e.OpenstackTFVars.LoadBalancerNameFlavorMapSC,
			},
		},
		api.WorkloadCluster: {
			api.Master: {
				&e.OpenstackTFVars.MasterNamesWC,
				e.OpenstackTFVars.MasterNameSizeMapWC,
			},
			api.Worker: {
				&e.OpenstackTFVars.WorkerNamesWC,
				e.OpenstackTFVars.WorkerNameSizeMapWC,
			},
			api.LoadBalancer: {
				&e.OpenstackTFVars.LoadBalancerNamesWC,
				e.OpenstackTFVars.LoadBalancerNameFlavorMapWC,
			},
		},
	}[cluster][nodeType]
}
