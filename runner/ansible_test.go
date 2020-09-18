package runner

import (
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testAnsibleConfig = &AnsibleConfig{
		AnsibleConfigPath: "config",
		InventoryPath:     "inventory",

		PlaybookPathDeployKubernetes: "deploycluster",
		PlaybookPathPrepareNodes:     "preparenodes",
		PlaybookPathJoinCluster:      "joincluster",

		KubeconfigPath: "kubeconfig",

		Env: map[string]string{},
	}
)

func TestAnsibleDeployKubernetes(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"ansible_playbook",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"ansible-playbook",
		"-i", testAnsibleConfig.InventoryPath,
		"--extra-vars", "kubeconfig_path="+testAnsibleConfig.KubeconfigPath,
		testAnsibleConfig.PlaybookPathDeployKubernetes,
	)
	wantCmd.Env = map[string]string{
		"ANSIBLE_CONFIG": testAnsibleConfig.AnsibleConfigPath,
	}

	r.Push(&TestCommand{Command: wantCmd})

	a := NewAnsible(logger, r, testAnsibleConfig)

	if err := a.DeployKubernetes(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}
