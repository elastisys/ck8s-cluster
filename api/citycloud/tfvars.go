package citycloud

import (
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

func (e *Cluster) CloneMachine(
	nodeType api.NodeType,
	name string,
) (string, error) {
	part := openstack.LookupMachinePartHelper(
		&e.tfvars,
		e.config.ClusterType,
		nodeType,
	)

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

func (e *Cluster) Machines() (machines []api.Machine) {
	for _, nodeType := range []api.NodeType{
		api.Master,
		api.Worker,
	} {
		part := openstack.LookupMachinePartHelper(
			&e.tfvars,
			e.config.ClusterType,
			nodeType,
		)
		for _, name := range *part.NameSlice {
			machines = append(machines, api.Machine{
				Name:     name,
				NodeType: nodeType,
			})
		}
	}
	return
}

func (e *Cluster) RemoveMachine(
	nodeType api.NodeType,
	name string,
) error {
	part := openstack.LookupMachinePartHelper(
		&e.tfvars,
		e.config.ClusterType,
		nodeType,
	)

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
