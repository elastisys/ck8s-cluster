package aws

import (
	"fmt"
	"strings"

	"github.com/elastisys/ck8s/api"
)

type tfOutputFQDNObject struct {
	Value string `json:"value"`
}

type tfOutputIPsObject struct {
	Value map[string]tfOutputIPsValue `json:"value"`
}

type tfOutputIPsValue struct {
	PrivateIP string `json:"private_ip"`
	PublicIP  string `json:"public_ip"`
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

	SCControlPlaneExternalLBFQDN tfOutputFQDNObject `json:"sc_master_external_loadbalancer_fqdn"`
	WCControlPlaneExternalLBFQDN tfOutputFQDNObject `json:"wc_master_external_loadbalancer_fqdn"`
	SCControlPlaneInternalLBFQDN tfOutputFQDNObject `json:"sc_master_internal_loadbalancer_fqdn"`
	WCControlPlaneInternalLBFQDN tfOutputFQDNObject `json:"wc_master_internal_loadbalancer_fqdn"`

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
		return e.SCControlPlaneInternalLBFQDN.Value
	case api.WorkloadCluster:
		return e.WCControlPlaneInternalLBFQDN.Value
	default:
		panic(fmt.Sprintf("invalid cluster type: %s", e.ClusterType))
	}
}

func (e *terraformOutput) ControlPlanePublicIP() string {
	switch e.ClusterType {
	case api.ServiceCluster:
		return e.SCControlPlaneExternalLBFQDN.Value
	case api.WorkloadCluster:
		return e.WCControlPlaneExternalLBFQDN.Value
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
