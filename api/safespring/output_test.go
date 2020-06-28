package safespring

import (
	"encoding/json"
	"errors"
	"io/ioutil"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/openstack"
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
		TerraformOutput: openstack.TerraformOutput{
			ClusterType: clusterType,
			ClusterName: clusterName,
		},
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
	testCases := map[api.ClusterType][]api.MachineState{
		api.ServiceCluster: {{
			Machine: api.Machine{
				NodeType: api.LoadBalancer,
				Name:     "loadbalancer-0",
			},
			PublicIP:  "159.100.242.14",
			PrivateIP: "172.16.0.4",
		}, {
			Machine: api.Machine{
				NodeType: api.Master,
				Name:     "master-0",
			},
			PublicIP:  "159.100.242.12",
			PrivateIP: "172.16.0.1",
		}, {
			Machine: api.Machine{
				NodeType: api.Worker,
				Name:     "worker-0",
			},
			PublicIP:  "159.100.242.13",
			PrivateIP: "172.16.0.2",
		}, {
			Machine: api.Machine{
				NodeType: api.Worker,
				Name:     "worker-1",
			},
			PublicIP:  "159.100.242.14",
			PrivateIP: "172.16.0.3",
		}},
		api.WorkloadCluster: {{
			Machine: api.Machine{
				NodeType: api.LoadBalancer,
				Name:     "loadbalancer-0",
			},
			PublicIP:  "159.100.242.17",
			PrivateIP: "172.16.0.7",
		}, {
			Machine: api.Machine{
				NodeType: api.Master,
				Name:     "master-0",
			},
			PublicIP:  "159.100.242.15",
			PrivateIP: "172.16.0.5",
		}, {
			Machine: api.Machine{
				NodeType: api.Worker,
				Name:     "worker-0",
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
