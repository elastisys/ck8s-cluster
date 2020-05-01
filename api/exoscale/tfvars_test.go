package exoscale

import (
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func TestCloneMachine(t *testing.T) {
	testName := "foo"
	testSize := "small"
	testESCap := 1

	type tfvarsPart struct {
		nameSlice []string
		sizeMap   map[string]string
		esCapMap  map[string]int
	}

	cluster := &ExoscaleCluster{
		BaseConfig: api.BaseConfig{},
		TFVarsConfig: &TFVarsConfig{
			MasterNamesSC:               []string{testName},
			MasterNameSizeMapSC:         map[string]string{testName: testSize},
			WorkerNamesSC:               []string{testName},
			WorkerNameSizeMapSC:         map[string]string{testName: testSize},
			ESLocalStorageCapacityMapSC: map[string]int{testName: testESCap},
			MasterNamesWC:               []string{testName},
			MasterNameSizeMapWC:         map[string]string{testName: testSize},
			WorkerNamesWC:               []string{testName},
			WorkerNameSizeMapWC:         map[string]string{testName: testSize},
			ESLocalStorageCapacityMapWC: map[string]int{testName: testESCap},
		},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		cluster.ClusterType = clusterType

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
			cluster.TFVarsConfig.MasterNamesSC,
			cluster.TFVarsConfig.MasterNameSizeMapSC,
			nil,
		},
		"sc worker": {
			cluster.TFVarsConfig.WorkerNamesSC,
			cluster.TFVarsConfig.WorkerNameSizeMapSC,
			cluster.TFVarsConfig.ESLocalStorageCapacityMapSC,
		},
		"wc master": {
			cluster.TFVarsConfig.MasterNamesWC,
			cluster.TFVarsConfig.MasterNameSizeMapWC,
			nil,
		},
		"wc worker": {
			cluster.TFVarsConfig.WorkerNamesWC,
			cluster.TFVarsConfig.WorkerNameSizeMapWC,
			cluster.TFVarsConfig.ESLocalStorageCapacityMapWC,
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
		if part.esCapMap != nil {
			if len(part.esCapMap) != 2 {
				t.Errorf("%s not cloned in es capacity map", machineType)
			}
			for _, esCap := range part.esCapMap {
				if esCap != testESCap {
					t.Errorf(
						"%s es capacity mismatch, want: %d, got: %d",
						machineType, part.esCapMap[testName], esCap,
					)
				}
			}
		}
	}
}

func TestRemoveMachine(t *testing.T) {
	testName := "bar"

	got, want := &ExoscaleCluster{}, &ExoscaleCluster{}

	got.TFVarsConfig = &TFVarsConfig{
		MasterNamesSC:               []string{testName},
		MasterNameSizeMapSC:         map[string]string{testName: "a"},
		WorkerNamesSC:               []string{testName},
		WorkerNameSizeMapSC:         map[string]string{testName: "a"},
		ESLocalStorageCapacityMapSC: map[string]int{testName: 1},
		MasterNamesWC:               []string{testName},
		MasterNameSizeMapWC:         map[string]string{testName: "a"},
		WorkerNamesWC:               []string{testName},
		WorkerNameSizeMapWC:         map[string]string{testName: "a"},
		ESLocalStorageCapacityMapWC: map[string]int{testName: 1},
	}

	want.TFVarsConfig = &TFVarsConfig{
		MasterNamesSC:               []string{},
		MasterNameSizeMapSC:         map[string]string{},
		WorkerNamesSC:               []string{},
		WorkerNameSizeMapSC:         map[string]string{},
		ESLocalStorageCapacityMapSC: map[string]int{},
		MasterNamesWC:               []string{},
		MasterNameSizeMapWC:         map[string]string{},
		WorkerNamesWC:               []string{},
		WorkerNameSizeMapWC:         map[string]string{},
		ESLocalStorageCapacityMapWC: map[string]int{},
	}

	for _, clusterType := range []api.ClusterType{
		api.ServiceCluster,
		api.WorkloadCluster,
	} {
		got.ClusterType = clusterType

		for _, nodeType := range []api.NodeType{api.Master, api.Worker} {
			if err := got.RemoveMachine(nodeType, testName); err != nil {
				t.Fatalf(
					"error while removing %s %s machine: %s",
					clusterType.String(), nodeType.String(), err,
				)
			}
		}
	}

	if diff := cmp.Diff(want.TFVarsConfig, got.TFVarsConfig); diff != "" {
		t.Errorf("mismatch (-want +got):\n%s", diff)
	}
}
