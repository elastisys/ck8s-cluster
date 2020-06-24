package aws

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestCloneMachine(t *testing.T) {
	testName := "foo"
	testSize := "small"

	type tfvarsPart struct {
		nameSizeMap map[string]string
	}

	cluster := Default(-1, "testName")

	cluster.tfvars.MasterNodesSC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNodesSC = map[string]string{testName: testSize}
	cluster.tfvars.MasterNodesWC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNodesWC = map[string]string{testName: testSize}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker} {
			if _, err := cluster.CloneMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while cloning %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	for machineType, part := range map[string]tfvarsPart{
		"sc master": {
			cluster.tfvars.MasterNodesSC,
		},
		"sc worker": {
			cluster.tfvars.WorkerNodesSC,
		},
		"wc master": {
			cluster.tfvars.MasterNodesWC,
		},
		"wc worker": {
			cluster.tfvars.WorkerNodesWC,
		},
	} {
		if len(part.nameSizeMap) != 2 {
			t.Errorf("%s machine not cloned in name slice", machineType)
		}
		for _, size := range part.nameSizeMap {
			if size != testSize {
				t.Errorf(
					"%s size mismatch, want: %s, got: %s",
					machineType, part.nameSizeMap[testName], size,
				)
			}
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := Default(-1, "testName"), Default(-1, "testName")

	got.tfvars = AWSTFVars{
		MasterNodesSC: map[string]string{testName: "a"},
		WorkerNodesSC: map[string]string{testName: "a"},
		MasterNodesWC: map[string]string{testName: "a"},
		WorkerNodesWC: map[string]string{testName: "a"},
	}

	want.tfvars = AWSTFVars{
		MasterNodesSC: map[string]string{},
		WorkerNodesSC: map[string]string{},
		MasterNodesWC: map[string]string{},
		WorkerNodesWC: map[string]string{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker} {
			if err := got.RemoveMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while removing %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	if diff := cmp.Diff(want.tfvars, got.tfvars); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
