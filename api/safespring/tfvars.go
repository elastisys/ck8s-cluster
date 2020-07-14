package safespring

import (
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

type SafespringTFVars struct {
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

	MasterAntiAffinityPolicySC string `hcl:"master_anti_affinity_policy_sc"`
	WorkerAntiAffinityPolicySC string `hcl:"worker_anti_affinity_policy_sc"`
	MasterAntiAffinityPolicyWC string `hcl:"master_anti_affinity_policy_wc"`
	WorkerAntiAffinityPolicyWC string `hcl:"worker_anti_affinity_policy_wc"`

	PublicIngressCIDRWhitelist []string `hcl:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `hcl:"api_server_whitelist" validate:"required"`
	NodeportWhitelist  []string `hcl:"nodeport_whitelist" validate:"required"`

	AWSDNSZoneID  string `hcl:"aws_dns_zone_id" validate:"required"`
	AWSDNSRoleARN string `hcl:"aws_dns_role_arn" validate:"required"`

	ExternalNetworkID   string `hcl:"external_network_id" validate:"required"`
	ExternalNetworkName string `hcl:"external_network_name" validate:"required"`

	// TODO: Combine these
	LoadBalancerNamesSC         []string          `hcl:"loadbalancer_names_sc" validate:"required"`
	LoadBalancerNameFlavorMapSC map[string]string `hcl:"loadbalancer_name_flavor_map_sc" validate:"required"`

	// TODO: Combine these
	LoadBalancerNamesWC         []string          `hcl:"loadbalancer_names_wc" validate:"required"`
	LoadBalancerNameFlavorMapWC map[string]string `hcl:"loadbalancer_name_flavor_map_wc" validate:"required"`
}

func (e *Cluster) CloneMachine(
	nodeType api.NodeType,
	name string,
) (string, error) {
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

	// TODO Find the root cause for this issue
	cloneName := strings.Replace(uuid.New().String(), "-", "", -1)

	size, ok := part.SizeMap[name]
	if !ok {
		return "", fmt.Errorf("machine not found: %s", name)
	}

	*part.NameSlice = append(*part.NameSlice, cloneName)
	part.SizeMap[cloneName] = size

	return cloneName, nil
}

func (e *Cluster) RemoveMachine(
	nodeType api.NodeType,
	name string,
) error {
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

	_, ok := part.SizeMap[name]
	if !ok {
		return fmt.Errorf("machine not found: %s", name)
	}

	for i, n := range *part.NameSlice {
		if n == name {
			*part.NameSlice = append(
				(*part.NameSlice)[:i],
				(*part.NameSlice)[i+1:]...,
			)
			break
		}
	}

	delete(part.SizeMap, name)

	return nil
}

func (e *Cluster) Machines() (machines []api.Machine) {
	for _, nodeType := range []api.NodeType{
		api.Master,
		api.Worker,
		api.LoadBalancer,
	} {
		part := e.lookupMachinePart(e.config.ClusterType, nodeType)
		for _, name := range *part.NameSlice {
			machines = append(machines, api.Machine{
				Name:     name,
				NodeType: nodeType,
			})
		}
	}
	return
}

func (e *Cluster) lookupMachinePart(
	cluster api.ClusterType,
	nodeType api.NodeType,
) openstack.TfvarsMachinePart {
	return map[api.ClusterType]map[api.NodeType]openstack.TfvarsMachinePart{
		api.ServiceCluster: {
			api.Master: {
				NameSlice: &e.tfvars.MasterNamesSC,
				SizeMap:   e.tfvars.MasterNameSizeMapSC,
			},
			api.Worker: {
				NameSlice: &e.tfvars.WorkerNamesSC,
				SizeMap:   e.tfvars.WorkerNameSizeMapSC,
			},
			api.LoadBalancer: {
				NameSlice: &e.tfvars.LoadBalancerNamesSC,
				SizeMap:   e.tfvars.LoadBalancerNameFlavorMapSC,
			},
		},
		api.WorkloadCluster: {
			api.Master: {
				NameSlice: &e.tfvars.MasterNamesWC,
				SizeMap:   e.tfvars.MasterNameSizeMapWC,
			},
			api.Worker: {
				NameSlice: &e.tfvars.WorkerNamesWC,
				SizeMap:   e.tfvars.WorkerNameSizeMapWC,
			},
			api.LoadBalancer: {
				NameSlice: &e.tfvars.LoadBalancerNamesWC,
				SizeMap:   e.tfvars.LoadBalancerNameFlavorMapWC,
			},
		},
	}[cluster][nodeType]
}
