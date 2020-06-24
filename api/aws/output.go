package aws

import (
	"fmt"
	"sort"
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

	ControlPlanePort int

	PrivateNetworkCIDR string

	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string
	KubeadmInitExtraArgs       string

	CalicoMTU int

	InternalLoadBalancerAnsibleGroups []string
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

func (e *terraformOutput) Machines() (machines []api.MachineState) {
	switch e.ClusterType {
	case api.ServiceCluster:
		machines = append(
			machines,
			e.GetMachinesState(api.Master, e.SCMasterIPs)...,
		)
		machines = append(
			machines,
			e.GetMachinesState(api.Worker, e.SCWorkerIPs)...,
		)
	case api.WorkloadCluster:
		machines = append(
			machines,
			e.GetMachinesState(api.Master, e.WCMasterIPs)...,
		)
		machines = append(
			machines,
			e.GetMachinesState(api.Worker, e.WCWorkerIPs)...,
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

func (e *terraformOutput) GetMachinesState(
	nodeType api.NodeType,
	IPs tfOutputIPsObject,
) (machines []api.MachineState) {
	for name, ipsValue := range IPs.Value {
		machines = append(machines, api.MachineState{
			NodeType:  nodeType,
			Name:      strings.TrimPrefix(name, e.ClusterName+"-"),
			PublicIP:  ipsValue.PublicIP,
			PrivateIP: ipsValue.PrivateIP,
		})
	}
	return
}
