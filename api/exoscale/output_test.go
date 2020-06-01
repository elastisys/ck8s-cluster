package exoscale

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
)

func testState(
	t *testing.T,
	clusterType api.ClusterType,
	clusterName string,
) api.ClusterState {
	switch clusterType {
	case api.ServiceCluster:
		clusterName += "-service-cluster"
	case api.WorkloadCluster:
		clusterName += "-workload-cluster"
	}

	tfOutput := &terraformOutput{
		ClusterType: clusterType,
		ClusterName: clusterName,
	}

	data, err := ioutil.ReadFile("testdata/terraform-output.json")
	if err != nil {
		t.Fatal(err)
	}

	if err := json.Unmarshal(data, &tfOutput); err != nil {
		t.Fatal(err)
	}

	return tfOutput
}

func TestTerraformOutputControlPlanePublicIP(t *testing.T) {
	testCases := map[api.ClusterType]string{
		api.ServiceCluster:  "89.145.167.47",
		api.WorkloadCluster: "89.145.166.90",
	}

	for clusterType, want := range testCases {
		tfOutput := testState(t, clusterType, "ck8stest")

		got := tfOutput.ControlPlanePublicIP()
		if got != want {
			t.Errorf(
				"control plane public IP mismatch, want: %s, got: %s",
				want, got,
			)
		}
	}
}

func TestTerraformOutputMachines(t *testing.T) {
	testCases := map[api.ClusterType][]api.MachineState{
		api.ServiceCluster: {{
			NodeType:  api.Master,
			Name:      "master-0",
			PublicIP:  "159.100.242.187",
			PrivateIP: "172.0.10.205",
		}, {
			NodeType:  api.Worker,
			Name:      "worker-0",
			PublicIP:  "159.100.242.78",
			PrivateIP: "172.0.10.59",
		}, {
			NodeType:  api.Worker,
			Name:      "worker-1",
			PublicIP:  "89.145.167.81",
			PrivateIP: "172.0.10.72",
		}},
		api.WorkloadCluster: {{
			NodeType:  api.Master,
			Name:      "master-0",
			PublicIP:  "159.100.244.19",
			PrivateIP: "172.0.10.132",
		}, {
			NodeType:  api.Worker,
			Name:      "worker-0",
			PublicIP:  "89.145.167.114",
			PrivateIP: "172.0.10.72",
		}},
	}

	for clusterType, wantMachines := range testCases {
		tfOutput := testState(t, clusterType, "ck8stest")

		gotMachines := tfOutput.Machines()

		if diff := cmp.Diff(wantMachines, gotMachines); diff != "" {
			t.Errorf("machines mismatch (-want +got):\n%s", diff)
		}

		for _, wantMachine := range wantMachines {
			gotMachine, err := tfOutput.Machine(
				wantMachine.NodeType,
				wantMachine.Name,
			)
			if err != nil {
				t.Error(err)
			}

			if diff := cmp.Diff(wantMachine, gotMachine); diff != "" {
				t.Errorf("machine mismatch (-want +got):\n%s", diff)
			}
		}
	}
}

func TestTerraformOutputMachinesNotFound(t *testing.T) {
	tfOutput := testState(t, api.ServiceCluster, "ck8stest")
	_, err := tfOutput.Machine(api.Master, "test")
	notFoundErr := &api.MachineStateNotFoundError{}
	if !errors.As(err, &notFoundErr) {
		t.Error("expected MachineStateNotFoundError")
	}
}
