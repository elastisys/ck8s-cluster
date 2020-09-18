package aws

import (
	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

// AWSTFVars TODO
type AWSTFVars struct {
	Region string `json:"region"`

	PrefixSC string `json:"prefix_sc"`
	PrefixWC string `json:"prefix_wc"`

	MachinesSC map[string]*api.Machine `json:"machines_sc" validate:"required,min=1"`
	MachinesWC map[string]*api.Machine `json:"machines_wc" validate:"required,min=1"`

	PublicIngressCIDRWhitelist []string `json:"public_ingress_cidr_whitelist" validate:"required"`
	APIServerWhitelist         []string `json:"api_server_whitelist" validate:"required"`
	NodeportWhitelist          []string `json:"nodeport_whitelist" validate:"required"`
}

func (e *Cluster) AddMachine(
	name string,
	machine *api.Machine,
) (string, error) {
	if name == "" {
		name = uuid.New().String()
	}

	machines := e.Machines()

	if _, ok := machines[name]; ok {
		return "", api.NewMachineAlreadyExistsError(name)
	}

	machines[name] = machine

	return name, nil
}

func (e *Cluster) Machines() map[string]*api.Machine {
	switch e.config.ClusterType {
	case api.ServiceCluster:
		if e.tfvars.MachinesSC == nil {
			e.tfvars.MachinesSC = map[string]*api.Machine{}
		}
		return e.tfvars.MachinesSC
	case api.WorkloadCluster:
		if e.tfvars.MachinesWC == nil {
			e.tfvars.MachinesWC = map[string]*api.Machine{}
		}
		return e.tfvars.MachinesWC
	}
	panic("invalid cluster type")
}

func (e *Cluster) RemoveMachine(name string) error {
	machines := e.Machines()
	delete(machines, name)
	return nil
}
