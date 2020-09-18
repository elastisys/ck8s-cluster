package runner

import (
	"errors"
	"fmt"
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testKubectlConfig = &KubectlConfig{
		KubeconfigPath: "kubeconfig",
		NodePrefix:     "prefix",
	}
	testNodeName        = "node"
	testFullNodeName    = testKubectlConfig.NodePrefix + "-" + testNodeName
	testDeleteResource  = "testResource"
	testDeleteExtraArgs = "testExtraArg"
)

func TestKubectlNodeExists(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_node_exists",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf("KUBECONFIG={} kubectl get node %s", testFullNodeName),
	)

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubectl(logger, r, testKubectlConfig)

	if err := k.NodeExists(testNodeName); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubectlNodeExistsNotFound(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_node_exists",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf("KUBECONFIG={} kubectl get node %s", testFullNodeName),
	)

	r.Push(&TestCommand{Command: wantCmd, Stderr: []byte("not found")})

	k := NewKubectl(logger, r, testKubectlConfig)

	if err := k.NodeExists(testNodeName); !errors.Is(err, NodeNotFoundErr) {
		t.Error("expected NodeNotFoundErr")
	}

	logTest.Diff(t)
}

func TestKubectlDrain(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_drain",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf(
			"KUBECONFIG={} kubectl drain --ignore-daemonsets --delete-local-data %s",
			testFullNodeName,
		),
	)

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubectl(logger, r, testKubectlConfig)

	if err := k.Drain(testNodeName); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubectlDeleteNode(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_delete_node",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf(
			"KUBECONFIG={} kubectl delete node %s",
			testFullNodeName,
		),
	)

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubectl(logger, r, testKubectlConfig)

	if err := k.DeleteNode(testNodeName); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubectlDeleteAll(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_delete_all",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf(
			"KUBECONFIG={} kubectl delete %s -A --all %s",
			testDeleteResource,
			testDeleteExtraArgs,
		),
	)

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubectl(logger, r, testKubectlConfig)

	if err := k.DeleteAll(testDeleteResource, testDeleteExtraArgs); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubectlIsUp(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_is_up",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		fmt.Sprintf("KUBECONFIG={} kubectl get --raw /api --request-timeout=2s"),
	)

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubectl(logger, r, testKubectlConfig)

	k.IsUp()

	logTest.Diff(t)
}
