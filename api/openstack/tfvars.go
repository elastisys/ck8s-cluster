package openstack

import (
	"strings"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

type TFVars struct {
	PrefixSC string `json:"prefix_sc"`
	PrefixWC string `json:"prefix_wc"`

	MachinesSC map[string]*api.Machine `json:"machines_sc" validate:"required,min=1"`
	MachinesWC map[string]*api.Machine `json:"machines_wc" validate:"required,min=1"`

	MasterAntiAffinityPolicySC string `json:"master_anti_affinity_policy_sc"`
	WorkerAntiAffinityPolicySC string `json:"worker_anti_affinity_policy_sc"`
	MasterAntiAffinityPolicyWC string `json:"master_anti_affinity_policy_wc"`
	WorkerAntiAffinityPolicyWC string `json:"worker_anti_affinity_policy_wc"`

	PublicIngressCIDRWhitelist []string `json:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `json:"api_server_whitelist" validate:"required"`
	NodeportWhitelist  []string `json:"nodeport_whitelist" validate:"required"`

	AWSDNSZoneID  string `json:"aws_dns_zone_id" validate:"required"`
	AWSDNSRoleARN string `json:"aws_dns_role_arn" validate:"required"`

	ExternalNetworkID   string `json:"external_network_id" validate:"required"`
	ExternalNetworkName string `json:"external_network_name" validate:"required"`
}

func (e *Cluster) AddMachine(
	name string,
	machine *api.Machine,
) (string, error) {
	if name == "" {
		// TODO Find the root cause for this issue
		name = strings.Replace(uuid.New().String(), "-", "", -1)
	}

	machines := e.Machines()

	if _, ok := machines[name]; ok {
		return "", api.NewMachineAlreadyExistsError(name)
	}

	machines[name] = machine

	return name, nil
}

func (e *Cluster) Machines() map[string]*api.Machine {
	switch e.Config.ClusterType {
	case api.ServiceCluster:
		if e.TFVars.MachinesSC == nil {
			e.TFVars.MachinesSC = map[string]*api.Machine{}
		}
		return e.TFVars.MachinesSC
	case api.WorkloadCluster:
		if e.TFVars.MachinesWC == nil {
			e.TFVars.MachinesWC = map[string]*api.Machine{}
		}
		return e.TFVars.MachinesWC
	}
	panic("invalid cluster type")
}

func (e *Cluster) RemoveMachine(name string) error {
	machines := e.Machines()
	delete(machines, name)
	return nil
}
