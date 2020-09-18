package exoscale

import (
	"fmt"
	"strings"

	"github.com/elastisys/ck8s/api"
)

type tfOutputPublicIPsValue struct {
	PublicIP  string `json:"public_ip"`
	PrivateIP string `json:"private_ip"`
}

type tfOutputIPsObject struct {
	Value map[string]tfOutputPublicIPsValue `json:"value"`
}

type tfOutputValue struct {
	Value string `json:"value"`
}

type terraformOutput struct {
	ClusterType api.ClusterType
	ClusterName string

	SCMasterIPs tfOutputIPsObject `json:"sc_master_ips"`
	SCWorkerIPs tfOutputIPsObject `json:"sc_worker_ips"`
	WCMasterIPs tfOutputIPsObject `json:"wc_master_ips"`
	WCWorkerIPs tfOutputIPsObject `json:"wc_worker_ips"`

	SCControlPlaneLBIP tfOutputValue `json:"sc_control_plane_lb_ip_address"`
	WCControlPlaneLBIP tfOutputValue `json:"wc_control_plane_lb_ip_address"`

	GlobalBaseDomain tfOutputValue `json:"domain_name"`

	ControlPlanePort int

	PrivateNetworkCIDR string

	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string
	KubeadmInitExtraArgs       string

	CalicoMTU int

	InternalLoadBalancerAnsibleGroups []string
}

func (e *terraformOutput) ControlPlaneEndpoint() string {
	return "127.0.0.1"
}

func (e *terraformOutput) BaseDomain() string {
	return e.GlobalBaseDomain.Value
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

func (e *terraformOutput) Machines() map[string]api.MachineState {
	machines := map[string]api.MachineState{}

	switch e.ClusterType {
	case api.ServiceCluster:
		e.machines(machines, api.Master, e.SCMasterIPs)
		e.machines(machines, api.Worker, e.SCWorkerIPs)
	case api.WorkloadCluster:
		e.machines(machines, api.Master, e.WCMasterIPs)
		e.machines(machines, api.Worker, e.WCWorkerIPs)
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

func (e *terraformOutput) machines(
	machines map[string]api.MachineState,
	nodeType api.NodeType,
	ips tfOutputIPsObject,
) {
	for name, ips := range ips.Value {
		name = strings.TrimPrefix(name, e.ClusterName+"-")
		machines[name] = api.MachineState{
			Machine: api.Machine{
				NodeType: nodeType,
				// TODO: Output machine size
			},
			PublicIP:  ips.PublicIP,
			PrivateIP: ips.PrivateIP,
		}
	}
}
