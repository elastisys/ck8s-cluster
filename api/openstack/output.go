package openstack

import (
	"fmt"
	"sort"
	"strings"

	"github.com/elastisys/ck8s/api"
)

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

type TerraformOutput struct {
	ClusterType api.ClusterType
	ClusterName string

	SCMasterIPs tfOutputIPsObject `json:"sc_master_ips"`
	SCWorkerIPs tfOutputIPsObject `json:"sc_worker_ips"`
	WCMasterIPs tfOutputIPsObject `json:"wc_master_ips"`
	WCWorkerIPs tfOutputIPsObject `json:"wc_worker_ips"`

	SCControlPlaneLBIPs tfOutputIPsObject `json:"sc_loadbalancer_ips"`
	WCControlPlaneLBIPs tfOutputIPsObject `json:"wc_loadbalancer_ips"`

	ControlPlanePort int

	PrivateNetworkCIDR string

	KubeadmInitCloudProvider   string
	KubeadmInitCloudConfigPath string
	KubeadmInitExtraArgs       string

	CalicoMTU int
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

func (e *TerraformOutput) Machines() (machines []api.MachineState) {
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
		machines = append(
			machines,
			e.machines(api.LoadBalancer, e.SCControlPlaneLBIPs)...,
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
		machines = append(
			machines,
			e.machines(api.LoadBalancer, e.WCControlPlaneLBIPs)...,
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

func (e *TerraformOutput) Machine(
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

func (e *TerraformOutput) machines(
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
