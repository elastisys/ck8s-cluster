package exoscale

import (
	"fmt"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

type ExoscaleTFVars struct {
	PrefixSC string `hcl:"prefix_sc"`
	PrefixWC string `hcl:"prefix_wc"`

	// TODO: Combine these
	MasterNamesSC       []string          `hcl:"master_names_sc" validate:"required,min=1"`
	MasterNameSizeMapSC map[string]string `hcl:"master_name_size_map_sc" validate:"required"`

	// TODO: Combine these
	WorkerNamesSC               []string          `hcl:"worker_names_sc"`
	WorkerNameSizeMapSC         map[string]string `hcl:"worker_name_size_map_sc"`
	ESLocalStorageCapacityMapSC map[string]int    `hcl:"es_local_storage_capacity_map_sc"`

	// TODO: Combine these
	MasterNamesWC       []string          `hcl:"master_names_wc" validate:"required,min=1"`
	MasterNameSizeMapWC map[string]string `hcl:"master_name_size_map_wc" validate:"required"`

	// TODO: Combine these
	WorkerNamesWC               []string          `hcl:"worker_names_wc"`
	WorkerNameSizeMapWC         map[string]string `hcl:"worker_name_size_map_wc"`
	ESLocalStorageCapacityMapWC map[string]int    `hcl:"es_local_storage_capacity_map_wc"`

	NFSSize string `hcl:"nfs_size"`

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
		for _, name := range *part.nameSlice {
			machines = append(machines, api.Machine{
				Name:     name,
				NodeType: nodeType,
			})
		}
	}
	return
}

func (e *Cluster) CloneMachine(
	nodeType api.NodeType,
	name string,
) (string, error) {
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

	cloneName := uuid.New().String()

	size, ok := part.sizeMap[name]
	if !ok {
		return "", fmt.Errorf("machine not found: %s", name)
	}

	if nodeType == api.Worker {
		esCap, ok := part.esLocalStorageCapacity[name]
		if !ok {
			return "", fmt.Errorf(
				"ES local storage capacity not found for machine: %s",
				name,
			)
		}
		part.esLocalStorageCapacity[cloneName] = esCap
	}

	*part.nameSlice = append(*part.nameSlice, cloneName)
	part.sizeMap[cloneName] = size

	return cloneName, nil
}

func (e *Cluster) RemoveMachine(
	nodeType api.NodeType,
	name string,
) error {
	// TODO: When we no longer need ClusterType these methods could be
	//		 implemented directly on the TFVars struct.
	part := e.lookupMachinePart(e.config.ClusterType, nodeType)

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
	delete(part.esLocalStorageCapacity, name)

	return nil
}

type tfvarsMachinePart struct {
	nameSlice              *[]string
	sizeMap                map[string]string
	esLocalStorageCapacity map[string]int
}

func (e *Cluster) lookupMachinePart(
	cluster api.ClusterType,
	nodeType api.NodeType,
) tfvarsMachinePart {
	return map[api.ClusterType]map[api.NodeType]tfvarsMachinePart{
		api.ServiceCluster: {
			api.Master: {
				&e.tfvars.MasterNamesSC,
				e.tfvars.MasterNameSizeMapSC,
				nil,
			},
			api.Worker: {
				&e.tfvars.WorkerNamesSC,
				e.tfvars.WorkerNameSizeMapSC,
				e.tfvars.ESLocalStorageCapacityMapSC,
			},
		},
		api.WorkloadCluster: {
			api.Master: {
				&e.tfvars.MasterNamesWC,
				e.tfvars.MasterNameSizeMapWC,
				nil,
			},
			api.Worker: {
				&e.tfvars.WorkerNamesWC,
				e.tfvars.WorkerNameSizeMapWC,
				e.tfvars.ESLocalStorageCapacityMapWC,
			},
		},
	}[cluster][nodeType]
}
