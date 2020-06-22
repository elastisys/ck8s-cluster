package safespring

import (
	"fmt"
	"sort"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

type terraformOutput struct {
	openstack.TerraformOutput `mapstructure:",squash"`
}

func (e *terraformOutput) Machines() (machines []api.MachineState) {
	switch e.ClusterType {
	case api.ServiceCluster:
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.Master, e.TerraformOutput.SCMasterIPs)...,
		)
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.Worker, e.TerraformOutput.SCWorkerIPs)...,
		)
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.LoadBalancer, e.SCControlPlaneLBIPs)...,
		)
	case api.WorkloadCluster:
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.Master, e.TerraformOutput.WCMasterIPs)...,
		)
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.Worker, e.TerraformOutput.WCWorkerIPs)...,
		)
		machines = append(
			machines,
			e.TerraformOutput.GetMachinesState(api.LoadBalancer, e.WCControlPlaneLBIPs)...,
		)
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}

	// TODO: Remove when machine states are no longer maps in output
	sort.Slice(machines, func(i, j int) bool {
		return machines[i].Name < machines[j].Name
	})

	return
}

func (e *terraformOutput) Machine(
	nodeType api.NodeType,
	name string,
) (machine api.MachineState, err error) {
	for _, machine = range e.Machines() {
		if machine.NodeType == nodeType && machine.Name == name {
			return
		}
	}

	err = &api.MachineStateNotFoundError{
		NodeType: nodeType,
		Name:     name,
	}
	return
}
