package openstack

import (
	"fmt"
	"strings"

	"github.com/elastisys/ck8s/api"
)

type TfOutputIPsObject struct {
	Value map[string]TfOutputIPsValue `json:"value"`
}

type TfOutputIPsValue struct {
	PrivateIP string `json:"private_ip"`
	PublicIP  string `json:"public_ip"`
}

type TfOutputValue struct {
	Value string `json:"value"`
}

type TerraformOutput struct {
	ClusterType api.ClusterType
	ClusterName string

	SCMasterIPs         TfOutputIPsObject `json:"sc_master_ips"`
	SCWorkerIPs         TfOutputIPsObject `json:"sc_worker_ips"`
	WCMasterIPs         TfOutputIPsObject `json:"wc_master_ips"`
	WCWorkerIPs         TfOutputIPsObject `json:"wc_worker_ips"`
	SCControlPlaneLBIPs TfOutputIPsObject `json:"sc_loadbalancer_ips"`
	WCControlPlaneLBIPs TfOutputIPsObject `json:"wc_loadbalancer_ips"`

	GlobalBaseDomain TfOutputValue `json:"domain_name"`

	ControlPlanePort int

	PrivateNetworkCIDR string

	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string
	KubeadmInitExtraArgs       string

	CalicoMTU int

	InternalLoadBalancerAnsibleGroups []string
}

func (e *TerraformOutput) BaseDomain() string {
	return e.GlobalBaseDomain.Value
}

func (e *TerraformOutput) ControlPlaneEndpoint() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		firstValue := ""
		for _, ipsValue := range e.SCControlPlaneLBIPs.Value {
			firstValue = ipsValue.PrivateIP
			break
		}
		return firstValue
	case api.WorkloadCluster:
		firstValue := ""
		for _, ipsValue := range e.WCControlPlaneLBIPs.Value {
			firstValue = ipsValue.PrivateIP
			break
		}
		return firstValue
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *TerraformOutput) ControlPlanePublicIP() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		firstValue := ""
		for _, ipsValue := range e.SCControlPlaneLBIPs.Value {
			firstValue = ipsValue.PublicIP
			break
		}
		return firstValue
	case api.WorkloadCluster:
		firstValue := ""
		for _, ipsValue := range e.WCControlPlaneLBIPs.Value {
			firstValue = ipsValue.PublicIP
			break
		}
		return firstValue
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *TerraformOutput) Machines() map[string]api.MachineState {
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

func (e *TerraformOutput) Machine(
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

func (e *TerraformOutput) GetMachinesState(
	machines map[string]api.MachineState,
	nodeType api.NodeType,
	IPs TfOutputIPsObject,
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
