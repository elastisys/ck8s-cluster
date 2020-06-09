package openstack

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

	cluster := Empty(-1)

	cluster.LoadBalancerNamesSC = []string{testName}
	cluster.LoadBalancerNameFlavorMapSC = map[string]string{testName: testSize}
	cluster.MasterNamesSC = []string{testName}
	cluster.MasterNameSizeMapSC = map[string]string{testName: testSize}
	cluster.WorkerNamesSC = []string{testName}
	cluster.WorkerNameSizeMapSC = map[string]string{testName: testSize}
	cluster.LoadBalancerNamesWC = []string{testName}
	cluster.LoadBalancerNameFlavorMapWC = map[string]string{testName: testSize}
	cluster.MasterNamesWC = []string{testName}
	cluster.MasterNameSizeMapWC = map[string]string{testName: testSize}
	cluster.WorkerNamesWC = []string{testName}
	cluster.WorkerNameSizeMapWC = map[string]string{testName: testSize}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.ClusterType = clusterType

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
			cluster.LoadBalancerNamesSC,
			cluster.LoadBalancerNameFlavorMapSC,
		},
		"sc master": {
			cluster.MasterNamesSC,
			cluster.MasterNameSizeMapSC,
		},
		"sc worker": {
			cluster.WorkerNamesSC,
			cluster.WorkerNameSizeMapSC,
		},
		"wc loadbalancer": {
			cluster.LoadBalancerNamesWC,
			cluster.LoadBalancerNameFlavorMapWC,
		},
		"wc master": {
			cluster.MasterNamesWC,
			cluster.MasterNameSizeMapWC,
		},
		"wc worker": {
			cluster.WorkerNamesWC,
			cluster.WorkerNameSizeMapWC,
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

	got, want := Empty(-1), Empty(-1)

	got.OpenstackTFVars = OpenstackTFVars{
		LoadBalancerNamesSC:         []string{testName},
		LoadBalancerNameFlavorMapSC: map[string]string{testName: "a"},
		MasterNamesSC:               []string{testName},
		MasterNameSizeMapSC:         map[string]string{testName: "a"},
		WorkerNamesSC:               []string{testName},
		WorkerNameSizeMapSC:         map[string]string{testName: "a"},
		LoadBalancerNamesWC:         []string{testName},
		LoadBalancerNameFlavorMapWC: map[string]string{testName: "a"},
		MasterNamesWC:               []string{testName},
		MasterNameSizeMapWC:         map[string]string{testName: "a"},
		WorkerNamesWC:               []string{testName},
		WorkerNameSizeMapWC:         map[string]string{testName: "a"},
	}

	want.OpenstackTFVars = OpenstackTFVars{
		LoadBalancerNamesSC:         []string{},
		LoadBalancerNameFlavorMapSC: map[string]string{},
		MasterNamesSC:               []string{},
		MasterNameSizeMapSC:         map[string]string{},
		WorkerNamesSC:               []string{},
		WorkerNameSizeMapSC:         map[string]string{},
		LoadBalancerNamesWC:         []string{},
		LoadBalancerNameFlavorMapWC: map[string]string{},
		MasterNamesWC:               []string{},
		MasterNameSizeMapWC:         map[string]string{},
		WorkerNamesWC:               []string{},
		WorkerNameSizeMapWC:         map[string]string{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker, api.LoadBalancer} {
			if err := got.RemoveMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while removing %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	if diff := cmp.Diff(want.OpenstackTFVars, got.OpenstackTFVars); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
