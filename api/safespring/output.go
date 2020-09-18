package safespring

import (
	"fmt"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
)

type terraformOutput struct {
	openstack.TerraformOutput
}

func (e *terraformOutput) Machines() map[string]api.MachineState {
	machines := map[string]api.MachineState{}

	switch e.ClusterType {
	case api.ServiceCluster:
		e.GetMachinesState(machines, api.Master, e.SCMasterIPs)
		e.GetMachinesState(machines, api.Worker, e.SCWorkerIPs)
		e.GetMachinesState(machines, api.LoadBalancer, e.SCControlPlaneLBIPs)
	case api.WorkloadCluster:
		e.GetMachinesState(machines, api.Master, e.WCMasterIPs)
		e.GetMachinesState(machines, api.Worker, e.WCWorkerIPs)
		e.GetMachinesState(machines, api.LoadBalancer, e.WCControlPlaneLBIPs)
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}

	return machines
}

func (e *terraformOutput) Machine(
	name string,
) (machine api.MachineState, err error) {
	var ok bool
	if machine, ok = e.Machines()[name]; !ok {
		err = &api.MachineStateNotFoundError{
			Name: name,
		}
	}
	return
}
