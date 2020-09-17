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

func TestKubectlServerVersion(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_server_version",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		"KUBECONFIG={} kubectl version -o json",
	)

	r.Push(&TestCommand{
		Command: wantCmd,
		Stdout: []byte(`{
  "clientVersion": {
    "major": "1",
    "minor": "16",
    "gitVersion": "v1.16.2",
    "gitCommit": "c97fe5036ef3df2967d086711e6c0c405941e14b",
    "gitTreeState": "clean",
    "buildDate": "2019-10-15T19:18:23Z",
    "goVersion": "go1.12.10",
    "compiler": "gc",
    "platform": "linux/amd64"
  },
  "serverVersion": {
    "major": "1",
    "minor": "17",
    "gitVersion": "v1.17.11",
    "gitCommit": "ea5f00d93211b7c80247bf607cfa422ad6fb5347",
    "gitTreeState": "clean",
    "buildDate": "2020-08-13T15:11:47Z",
    "goVersion": "go1.13.15",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}`),
	})

	wantVersion := "v1.17.11"

	k := NewKubectl(logger, r, testKubectlConfig)

	gotVersion, err := k.ServerVersion()
	if err != nil {
		t.Error(err)
	}

	if gotVersion != wantVersion {
		t.Errorf(
			"version mismatch, want: %s, got: %s",
			wantVersion, gotVersion,
		)
	}

	logTest.Diff(t)
}

func TestKubectlServerVersionMissingServerVersionOutput(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_server_version",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		"KUBECONFIG={} kubectl version -o json",
	)

	r.Push(&TestCommand{
		Command: wantCmd,
		Stdout: []byte(`{
  "clientVersion": {
    "major": "1",
    "minor": "16",
    "gitVersion": "v1.16.2",
    "gitCommit": "c97fe5036ef3df2967d086711e6c0c405941e14b",
    "gitTreeState": "clean",
    "buildDate": "2019-10-15T19:18:23Z",
    "goVersion": "go1.12.10",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}`),
	})

	k := NewKubectl(logger, r, testKubectlConfig)

	_, err := k.ServerVersion()
	if !errors.Is(err, ServerVersionMissingErr) {
		t.Errorf("expected error '%s', got '%s'", ServerVersionMissingErr, err)
	}

	logTest.Diff(t)
}

func TestKubectlServerVersionEmptyOutput(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubectl_server_version",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", testKubectlConfig.KubeconfigPath,
		"KUBECONFIG={} kubectl version -o json",
	)

	r.Push(&TestCommand{
		Command: wantCmd,
		Stdout:  []byte(``),
	})

	k := NewKubectl(logger, r, testKubectlConfig)

	if _, err := k.ServerVersion(); err == nil {
		t.Error("expected error")
	}

	logTest.Diff(t)
}
