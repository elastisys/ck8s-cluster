package safespring

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestCloneMachine(t *testing.T) {
	testName := "foo"
	testSize := "small"

	type tfvarsPart struct {
		nameSlice []string
		sizeMap   map[string]string
	}

	cluster := Default(-1, "")

	cluster.tfvars.LoadBalancerNamesSC = []string{testName}
	cluster.tfvars.LoadBalancerNameFlavorMapSC = map[string]string{testName: testSize}
	cluster.tfvars.MasterNamesSC = []string{testName}
	cluster.tfvars.MasterNameSizeMapSC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNamesSC = []string{testName}
	cluster.tfvars.WorkerNameSizeMapSC = map[string]string{testName: testSize}
	cluster.tfvars.LoadBalancerNamesWC = []string{testName}
	cluster.tfvars.LoadBalancerNameFlavorMapWC = map[string]string{testName: testSize}
	cluster.tfvars.MasterNamesWC = []string{testName}
	cluster.tfvars.MasterNameSizeMapWC = map[string]string{testName: testSize}
	cluster.tfvars.WorkerNamesWC = []string{testName}
	cluster.tfvars.WorkerNameSizeMapWC = map[string]string{testName: testSize}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker, api.LoadBalancer} {
			if _, err := cluster.CloneMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while cloning %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	for machineType, part := range map[string]tfvarsPart{
		"sc loadbalancer": {
			cluster.tfvars.LoadBalancerNamesSC,
			cluster.tfvars.LoadBalancerNameFlavorMapSC,
		},
		"sc master": {
			cluster.tfvars.MasterNamesSC,
			cluster.tfvars.MasterNameSizeMapSC,
		},
		"sc worker": {
			cluster.tfvars.WorkerNamesSC,
			cluster.tfvars.WorkerNameSizeMapSC,
		},
		"wc loadbalancer": {
			cluster.tfvars.LoadBalancerNamesWC,
			cluster.tfvars.LoadBalancerNameFlavorMapWC,
		},
		"wc master": {
			cluster.tfvars.MasterNamesWC,
			cluster.tfvars.MasterNameSizeMapWC,
		},
		"wc worker": {
			cluster.tfvars.WorkerNamesWC,
			cluster.tfvars.WorkerNameSizeMapWC,
		},
	} {
		if len(part.nameSlice) != 2 {
			t.Errorf("%s machine not cloned in name slice", machineType)
		}
		if len(part.sizeMap) != 2 {
			t.Errorf("%s machine not cloned in size map", machineType)
		}
		for _, size := range part.sizeMap {
			if size != testSize {
				t.Errorf(
					"%s size mismatch, want: %s, got: %s",
					machineType, part.sizeMap[testName], size,
				)
			}
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := Default(-1, ""), Default(-1, "")

	got.tfvars = SafespringTFVars{
		MasterNamesSC:               []string{testName},
		MasterNameSizeMapSC:         map[string]string{testName: "a"},
		WorkerNamesSC:               []string{testName},
		WorkerNameSizeMapSC:         map[string]string{testName: "a"},
		MasterNamesWC:               []string{testName},
		MasterNameSizeMapWC:         map[string]string{testName: "a"},
		WorkerNamesWC:               []string{testName},
		WorkerNameSizeMapWC:         map[string]string{testName: "a"},
		LoadBalancerNamesSC:         []string{testName},
		LoadBalancerNameFlavorMapSC: map[string]string{testName: "a"},
		LoadBalancerNamesWC:         []string{testName},
		LoadBalancerNameFlavorMapWC: map[string]string{testName: "a"},
	}

	want.tfvars = SafespringTFVars{
		MasterNamesSC:               []string{},
		MasterNameSizeMapSC:         map[string]string{},
		WorkerNamesSC:               []string{},
		WorkerNameSizeMapSC:         map[string]string{},
		MasterNamesWC:               []string{},
		MasterNameSizeMapWC:         map[string]string{},
		WorkerNamesWC:               []string{},
		WorkerNameSizeMapWC:         map[string]string{},
		LoadBalancerNamesSC:         []string{},
		LoadBalancerNameFlavorMapSC: map[string]string{},
		LoadBalancerNamesWC:         []string{},
		LoadBalancerNameFlavorMapWC: map[string]string{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.config.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker, api.LoadBalancer} {
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
