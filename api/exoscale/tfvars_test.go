package exoscale

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestAddMachine(t *testing.T) {
	cluster := Default(-1, "testName")

	want := &api.Machine{
		NodeType: api.Master,
		Size:     "Small",
		Image:    "test",
		ProviderSettings: MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType

		name, err := cluster.AddMachine("", want)
		if err != nil {
			t.Fatalf(
				"error while adding %s machine: %s",
				clusterType.String(), err,
			)
		}

		machines := cluster.Machines()

		got, ok := machines[name]
		if !ok {
			t.Errorf(
				"machine missing: %s", name,
			)
		}

		if diff := cmp.Diff(want, got); diff != "" {
			t.Errorf("machine mismatch (-want +got):\n%s", diff)
		}
	}
}

func TestAddMachineWithName(t *testing.T) {
	name := "foo"

	cluster := Default(-1, "testName")

	want := &api.Machine{
		NodeType: api.Worker,
		Size:     "Small",
		Image:    "test",
		ProviderSettings: MachineSettings{
			ESLocalStorageCapacity: 10,
		},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType

		_, err := cluster.AddMachine(name, want)
		if err != nil {
			t.Fatalf(
				"error while adding %s machine: %s",
				clusterType.String(), err,
			)
		}

		machines := cluster.Machines()

		got, ok := machines[name]
		if !ok {
			t.Errorf(
				"machine missing: %s", name,
			)
		}

		if diff := cmp.Diff(want, got); diff != "" {
			t.Errorf("machine mismatch (-want +got):\n%s", diff)
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := Default(-1, "testName"), Default(-1, "testName")

	got.tfvars = ExoscaleTFVars{
		MachinesSC: map[string]*api.Machine{
			testName: {
				NodeType: api.Master,
				Size:     "Small",
				Image:    "test",
				ProviderSettings: MachineSettings{
					ESLocalStorageCapacity: 10,
				},
			},
		},
		MachinesWC: map[string]*api.Machine{
			testName: {
				NodeType: api.Worker,
				Size:     "Large",
				Image:    "test",
			},
		},
	}

	want.tfvars = ExoscaleTFVars{
		MachinesSC: map[string]*api.Machine{},
		MachinesWC: map[string]*api.Machine{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.config.ClusterType = clusterType

		if err := got.RemoveMachine(testName); err != nil {
			t.Fatalf(
				"error while removing %s machine: %s",
				clusterType.String(), err,
			)
		}
	}

	if diff := cmp.Diff(want.tfvars, got.tfvars); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
