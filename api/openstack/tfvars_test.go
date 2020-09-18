package openstack

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestAddMachine(t *testing.T) {
	cluster := Default(-1, "", "testName")

	want := &api.Machine{
		NodeType: api.Master,
		Size:     "6d4ed3aa-396a-4005-a599-a3b1273c60ce",
		Image:    "test",
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.Config.ClusterType = clusterType

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

	cluster := Default(-1, "", "testName")

	want := &api.Machine{
		NodeType: api.Master,
		Size:     "6d4ed3aa-396a-4005-a599-a3b1273c60ce",
		Image:    "test",
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.Config.ClusterType = clusterType

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

	got := Default(-1, api.Safespring, "testName")
	want := Default(-1, api.CityCloud, "testName")

	got.TFVars = TFVars{
		MachinesSC: map[string]*api.Machine{
			testName: {
				NodeType: api.Master,
				Size:     "a1093fde-0772-474b-aced-42a5a2d36814",
			},
		},
		MachinesWC: map[string]*api.Machine{
			testName: {
				NodeType: api.Worker,
				Size:     "3232fa6c-3af1-4608-b0f9-acce2415a7a8",
			},
		},
	}

	want.TFVars = TFVars{
		MachinesSC: map[string]*api.Machine{},
		MachinesWC: map[string]*api.Machine{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.Config.ClusterType = clusterType

		if err := got.RemoveMachine(testName); err != nil {
			t.Fatalf(
				"error while removing %s machine: %s",
				clusterType.String(), err,
			)
		}
	}

	if diff := cmp.Diff(want.TFVars, got.TFVars); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
