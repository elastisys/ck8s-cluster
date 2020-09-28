package azure

import (
	"fmt"
	"strings"

	"github.com/elastisys/ck8s/api"
)

type tfOutputValue struct {
	Value string `json:"value"`
}

type terraformOutput struct {
	ClusterType api.ClusterType
	ClusterName string

	SCMasterIPs tfOutputValue `json:"sc_master_ips"`
	SCWorkerIPs tfOutputValue `json:"sc_worker_ips"`
	WCMasterIPs tfOutputValue `json:"wc_master_ips"`
	WCWorkerIPs tfOutputValue `json:"wc_worker_ips"`

	SCControlPlaneLBIPAddress tfOutputValue `json:"sc_control_plane_lb_ip_address"`
	WCControlPlaneLBIPAddress tfOutputValue `json:"wc_control_plane_lb_ip_address"`

	GlobalBaseDomain tfOutputValue `json:"domain_name"`

	ControlPlanePort int

	PrivateNetworkCIDR string

	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string
	KubeadmInitExtraArgs       string

	CalicoMTU int

	InternalLoadBalancerAnsibleGroups []string
}

func (e *terraformOutput) BaseDomain() string {
	return e.GlobalBaseDomain.Value
}

func (e *terraformOutput) ControlPlaneEndpoint() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		return e.SCControlPlaneLBIPAddress.Value
	case api.WorkloadCluster:
		return e.WCControlPlaneLBIPAddress.Value
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *terraformOutput) ControlPlanePublicIP() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		return e.SCControlPlaneLBIPAddress.Value
	case api.WorkloadCluster:
		return e.WCControlPlaneLBIPAddress.Value
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *terraformOutput) Machines() map[string]api.MachineState {
	machines := map[string]api.MachineState{}

	switch e.ClusterType {
	case api.ServiceCluster:
		e.GetMachinesState(machines, api.Master, e.SCMasterIPs)
		e.GetMachinesState(machines, api.Worker, e.SCWorkerIPs)
	case api.WorkloadCluster:
		e.GetMachinesState(machines, api.Master, e.WCMasterIPs)
		e.GetMachinesState(machines, api.Worker, e.WCWorkerIPs)
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

func (e *terraformOutput) GetMachinesState(
	machines map[string]api.MachineState,
	nodeType api.NodeType,
	IPs tfOutputIPsObject,
) {
	for name, ipsValue := range IPs.Value {
		name = strings.TrimPrefix(name, e.ClusterName+"-")
		machines[name] = api.MachineState{
			Machine: api.Machine{
				NodeType: nodeType,
				// TODO: Output machine size
			},
			PublicIP:  ipsValue.PublicIP,
			PrivateIP: ipsValue.PrivateIP,
		}
	}
}
