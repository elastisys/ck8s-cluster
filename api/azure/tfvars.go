package azure

import (
	"fmt"
	"strings"

	"github.com/google/uuid"

	"github.com/elastisys/ck8s/api"
)

type AzureTFVars struct {
	PrefixSC string `json:"prefix_sc" mapstructure:"prefix_sc"`
	PrefixWC string `json:"prefix_wc" mapstructure:"prefix_wc"`

	MachinesSC map[string]*api.Machine `json:"machines_sc" mapstructure:"machines_sc" validate:"required,min=1"`
	MachinesWC map[string]*api.Machine `json:"machines_wc" mapstructure:"machines_wc" validate:"required,min=1"`

	PublicIngressCIDRWhitelist []string `json:"public_ingress_cidr_whitelist" mapstructure:"public_ingress_cidr_whitelist" validate:"required"`

	APIServerWhitelist []string `json:"api_server_whitelist" mapstructure:"api_server_whitelist" validate:"required"`
	NodeportWhitelist  []string `json:"nodeport_whitelist" mapstructure:"nodeport_whitelist" validate:"required"`
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

func (e *Cluster) AddMachine(
	name string,
	machine *api.Machine,
) (string, error) {
	maxNameLen := nameSettings().maxNameLen
	minAutoNameLen := nameSettings().minAutoNameLen

	if name == "" {
		name = strings.Replace(uuid.New().String(), "-", "", -1)

		if len(api.NameHelper(&e.config.BaseConfig)+"-"+name) > maxNameLen {
			newNameLen := maxNameLen - len(api.NameHelper(&e.config.BaseConfig)+"-")
			if newNameLen < minAutoNameLen {
				return "", fmt.Errorf("environment name too long, cannot autogenerate name")
			}

			name = name[0:newNameLen]
		}
	}

	if len(api.NameHelper(&e.config.BaseConfig)+"-")+len(name) > maxNameLen {
		return "", fmt.Errorf("machine name cannot be longer than %d characters long", maxNameLen)
	}

	machines := e.Machines()

	if _, ok := machines[name]; ok {
		return "", api.NewMachineAlreadyExistsError(name)
	}

	machines[name] = machine

	return name, nil
}

func (e *Cluster) RemoveMachine(name string) error {
	delete(e.Machines(), name)
	return nil
}
