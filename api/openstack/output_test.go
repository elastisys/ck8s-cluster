package openstack

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

	tfOutput := &TerraformOutput{
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

func TestTerraformOutputBaseDomain(t *testing.T) {
	testCases := map[api.ClusterType]string{
		api.ServiceCluster:  "ck8stest.elastisys.se",
		api.WorkloadCluster: "ck8stest.elastisys.se",
	}

	for clusterType, want := range testCases {
		tfOutput := testState(t, clusterType, "ck8stest")

		got := tfOutput.BaseDomain()
		if got != want {
			t.Errorf(
				"Base domain mismatch, want: %s, got: %s",
				want, got,
			)
		}
	}
}

func TestTerraformOutputControlPlanePublicIP(t *testing.T) {
	testCases := map[api.ClusterType]string{
		api.ServiceCluster:  "159.100.242.14",
		api.WorkloadCluster: "159.100.242.17",
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
	testCases := map[api.ClusterType]map[string]api.MachineState{
		api.ServiceCluster: {
			"master-0": {
				Machine: api.Machine{
					NodeType: api.Master,
				},
				PublicIP:  "159.100.242.12",
				PrivateIP: "172.16.0.1",
			},
			"worker-0": {
				Machine: api.Machine{
					NodeType: api.Worker,
				},
				PublicIP:  "159.100.242.13",
				PrivateIP: "172.16.0.2",
			},
			"worker-1": {
				Machine: api.Machine{
					NodeType: api.Worker,
				},
				PublicIP:  "159.100.242.14",
				PrivateIP: "172.16.0.3",
			}},
		api.WorkloadCluster: {
			"master-0": {
				Machine: api.Machine{
					NodeType: api.Master,
				},
				PublicIP:  "159.100.242.15",
				PrivateIP: "172.16.0.5",
			},
			"worker-0": {
				Machine: api.Machine{
					NodeType: api.Worker,
				},
				PublicIP:  "159.100.242.16",
				PrivateIP: "172.16.0.6",
			}},
	}

	for clusterType, wantMachines := range testCases {
		tfOutput := testState(t, clusterType, "ck8stest")

		gotMachines := tfOutput.Machines()

		if diff := cmp.Diff(wantMachines, gotMachines); diff != "" {
			t.Errorf("machines mismatch (-want +got):\n%s", diff)
		}

		for name, wantMachine := range wantMachines {
			gotMachine, err := tfOutput.Machine(name)
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
	_, err := tfOutput.Machine("test")
	notFoundErr := &api.MachineStateNotFoundError{}
	if !errors.As(err, &notFoundErr) {
		t.Error("expected MachineStateNotFoundError")
	}
}
