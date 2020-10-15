package azure

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"

	"github.com/elastisys/ck8s/api"
)

func TestAddMachine(t *testing.T) {
	cluster := Default(-1, "testName")

	want := &api.Machine{
		NodeType: api.Master,
		Size:     "Standard_D2_v3",
		Image:    api.NewImage("test", "v1.2.3"),
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

		if diff := cmp.Diff(
			want,
			got,
			cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
		); diff != "" {
			t.Errorf("machine mismatch (-want +got):\n%s", diff)
		}
	}
}

func TestAddMachineWithName(t *testing.T) {
	name := "foo"

	cluster := Default(-1, "testName")

	want := &api.Machine{
		NodeType: api.Worker,
		Size:     "Standard_D2_v3",
		Image:    api.NewImage("test", "v1.2.3"),
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

		if diff := cmp.Diff(
			want,
			got,
			cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
		); diff != "" {
			t.Errorf("machine mismatch (-want +got):\n%s", diff)
		}
	}
}

func TestAddMachineNameCheck(t *testing.T) {
	cluster := Default(-1, "testName")

	want := &api.Machine{
		NodeType: api.Worker,
		Size:     "Standard_D2_v3",
		Image:    api.NewImage("test", "v1.2.3"),
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType
		environmentName := api.NameHelper(&cluster.config.BaseConfig) + "-"
		environmentNameLen := len(environmentName)
		maxNameLen := nameSettings().maxNameLen

		var longName string
		var okeyName string

		for i := 0; i < maxNameLen-environmentNameLen; i++ {
			longName = longName + "a"
			okeyName = okeyName + "b"
		}

		longName = longName + "a"

		_, err := cluster.AddMachine(longName, want)
		if err == nil {
			t.Fatalf(
				"expected %s (%d chars) to be longer than %d characters, when adding %s cluster",
				environmentName+longName,
				len(environmentName+longName),
				maxNameLen,
				clusterType.String(),
			)
		}

		_, err = cluster.AddMachine(okeyName, want)
		if err != nil {
			t.Fatalf(
				"expected %s (%d chars) to not be longer than %d characters, when adding %s cluster: %s",
				environmentName+okeyName,
				len(environmentName+okeyName),
				maxNameLen,
				clusterType.String(),
				err,
			)
		}

		machines := cluster.Machines()

		_, ok := machines[longName]
		if ok {
			t.Errorf("machine not expected: %s", longName)
		}

		got, ok := machines[okeyName]
		if !ok {
			t.Errorf(
				"machine missing: %s", okeyName,
			)
		}

		if diff := cmp.Diff(
			want,
			got,
			cmpopts.IgnoreFields(api.Image{}, "KubeletVersion"),
		); diff != "" {
			t.Errorf("machine mismatch (-want +got):\n%s", diff)
		}
	}
}

func TestAddMachineNameCheckLongEnvironment(t *testing.T) {
	want := &api.Machine{
		NodeType: api.Worker,
		Size:     "Standard_D2_v3",
		Image:    api.NewImage("test", "v1.2.3"),
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		clusterLongName := Default(-1, "")
		clusterOkeyName := Default(-1, "")
		clusterLongName.config.ClusterType = clusterType
		clusterOkeyName.config.ClusterType = clusterType

		maxNameLen := nameSettings().maxNameLen
		minAutoNameLen := nameSettings().minAutoNameLen
		for i := 0; i < maxNameLen; i++ {
			clusterLongName.config.EnvironmentName = clusterLongName.config.EnvironmentName + "a"
			clusterOkeyName.config.EnvironmentName = clusterOkeyName.config.EnvironmentName + "b"

			if maxNameLen-len(api.NameHelper(&clusterLongName.config.BaseConfig)+"-") == minAutoNameLen {
				break
			}
		}

		clusterLongName.config.EnvironmentName = clusterLongName.config.EnvironmentName + "a"

		environmentLongName := api.NameHelper(&clusterLongName.config.BaseConfig) + "-"
		environmentOkeyName := api.NameHelper(&clusterOkeyName.config.BaseConfig) + "-"
		environmentLongNameLen := len(environmentLongName)
		environmentOkeyNameLen := len(environmentOkeyName)

		_, err := clusterLongName.AddMachine("", want)
		if err == nil {
			t.Fatalf(
				"expected name generation to fail when using environment name %s (%d chars for autogeneration) when adding %s cluster",
				environmentLongName,
				maxNameLen-environmentLongNameLen,
				clusterType.String(),
			)
		}

		_, err = clusterOkeyName.AddMachine("", want)
		if err != nil {
			t.Fatalf(
				"expected name generation not to fail when using environment name %s (%d chars for autogeneration) when adding %s cluster: %s",
				environmentOkeyName,
				maxNameLen-environmentOkeyNameLen,
				clusterType.String(),
				err,
			)
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := Default(-1, "testName"), Default(-1, "testName")

	got.tfvars = AzureTFVars{
		MachinesSC: map[string]*api.Machine{
			testName: {
				NodeType: api.Master,
				Size:     "Standard_D2_v3",
				Image:    api.NewImage("test", "v1.2.3"),
			},
		},
		MachinesWC: map[string]*api.Machine{
			testName: {
				NodeType: api.Worker,
				Size:     "Standard_D4_v3",
				Image:    api.NewImage("test", "v1.2.3"),
			},
		},
	}

	want.tfvars = AzureTFVars{
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
