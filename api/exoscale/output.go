package exoscale

import (
	"fmt"
	"sort"
	"strings"

	"github.com/elastisys/ck8s/api"
)

type tfOutputPublicIPsValue struct {
	PublicIP string `json:"public_ip"`
}

type tfOutputPublicIPsObject struct {
	Value map[string]tfOutputPublicIPsValue `json:"value"`
}

type tfOutputValue struct {
	Value string `json:"value"`
}

type terraformOutput struct {
	ClusterType api.ClusterType
	ClusterName string

	SCMasterIPs tfOutputPublicIPsObject `json:"sc_master_ips"`
	SCWorkerIPs tfOutputPublicIPsObject `json:"sc_worker_ips"`
	WCMasterIPs tfOutputPublicIPsObject `json:"wc_master_ips"`
	WCWorkerIPs tfOutputPublicIPsObject `json:"wc_worker_ips"`

	SCControlPlaneLBIP tfOutputValue `json:"sc_control_plane_lb_ip_address"`
	WCControlPlaneLBIP tfOutputValue `json:"wc_control_plane_lb_ip_address"`
}

func (e *terraformOutput) ControlPlanePublicIP() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		return e.SCControlPlaneLBIP.Value
	case api.WorkloadCluster:
		return e.WCControlPlaneLBIP.Value
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *terraformOutput) Machines() (machines []api.MachineState) {
	switch e.ClusterType {
	case api.ServiceCluster:
		machines = append(
			machines,
			e.machines(api.Master, e.SCMasterIPs)...,
		)
		machines = append(
			machines,
			e.machines(api.Worker, e.SCWorkerIPs)...,
		)
	case api.WorkloadCluster:
		machines = append(
			machines,
			e.machines(api.Master, e.WCMasterIPs)...,
		)
		machines = append(
			machines,
			e.machines(api.Worker, e.WCWorkerIPs)...,
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

func (e *terraformOutput) machines(
	nodeType api.NodeType,
	publicIPs tfOutputPublicIPsObject,
) (machines []api.MachineState) {
	for name, publicIP := range publicIPs.Value {
		machines = append(machines, api.MachineState{
			NodeType:  nodeType,
			Name:      strings.TrimPrefix(name, e.ClusterName+"-"),
			PublicIP:  publicIP.PublicIP,
			PrivateIP: publicIP.PublicIP, // TODO: private ip
		})
	}
	return
}
