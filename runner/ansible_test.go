package runner

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"os"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/testutil"
)

var (
	testAnsibleConfigPath                = "config"
	testAnsibleInventoryPath             = "inventory"
	testAnsiblePlaybookDeployClusterPath = "deploycluster"
	testAnsiblePlaybookPrepareNodesPath  = "preparenodes"
	testAnsiblePlaybookJoinClusterPath   = "joincluster"
	testAnsibleKubeconfigPath            = "kubeconfig"
	testAnsibleCRDFilePath               = "crd"
)

func TestAnsibleDeployCluster(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"ansible_playbook",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"ansible-playbook",
		"-i", testAnsibleInventoryPath,
		"--extra-vars", "kubeconfig_path="+testAnsibleKubeconfigPath,
		"--extra-vars", "crd_file_path="+testAnsibleCRDFilePath,
		testAnsiblePlaybookDeployClusterPath,
	)
	wantCmd.Env = map[string]string{
		"ANSIBLE_CONFIG": testAnsibleConfigPath,
	}

	r.Push(&TestCommand{Command: wantCmd})

	a := NewAnsible(
		logger, r, testAnsibleConfigPath, testAnsibleInventoryPath,
		testAnsiblePlaybookDeployClusterPath,
		testAnsiblePlaybookPrepareNodesPath,
		testAnsiblePlaybookJoinClusterPath,
	)

	if err := a.DeployKubernetes(
		testKubeconfigPath,
		testAnsibleCRDFilePath,
	); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestRenderAnsibleInventory(t *testing.T) {
	type testCase struct {
		ansibleInventoryPath string
		terraformOutputPath  string
		cluster              api.Cluster
	}

	sc := exoscale.Default(api.ServiceCluster)
	sc.EnvironmentName = "ck8stest"

	wc := exoscale.Default(api.WorkloadCluster)
	wc.EnvironmentName = "ck8stest"

	testCases := []testCase{{
		"testdata/exoscale-ansible-hosts-sc.ini",
		"testdata/exoscale-terraform-output.json",
		sc,
	}, {
		"testdata/exoscale-ansible-hosts-wc.ini",
		"testdata/exoscale-terraform-output.json",
		wc,
	}}

	for _, tc := range testCases {
		var inventory bytes.Buffer

		state, err := tc.cluster.State(func(state interface{}) error {
			tfOutputData, err := ioutil.ReadFile(tc.terraformOutputPath)
			if err != nil {
				return err
			}
			return json.Unmarshal(tfOutputData, state)
		})
		if err != nil {
			t.Fatal(err)
		}

		if err := RenderAnsibleInventory(
			tc.cluster,
			state,
			&inventory,
		); err != nil {
			t.Fatal(err)
		}

		f, err := os.Open(tc.ansibleInventoryPath)
		if err != nil {
			t.Fatal(err)
		}

		want, err := ioutil.ReadAll(f)
		if err != nil {
			t.Fatal(err)
		}

		if diff := cmp.Diff(string(want), inventory.String()); diff != "" {
			t.Errorf("log mismatch (-want +got):\n%s", diff)
		}
	}
}
