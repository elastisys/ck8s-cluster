package runner

import (
	"encoding/json"
	"errors"
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testTerraformConfig = &TerraformConfig{
		Path:              "path",
		Workspace:         "workspace",
		DataDirPath:       "datadir",
		BackendConfigPath: "backendconfig",
		TFVarsPath:        "tfvars",

		Target: "test-target",

		Env: map[string]string{
			"foo": "bar",
		},
	}
)

func newTerraformTestCommand(args ...string) *Command {
	cmd := NewCommand(
		"terraform", args...,
	)
	cmd.Dir = testTerraformConfig.Path
	cmd.Env = map[string]string{
		"TF_DATA_DIR":  testTerraformConfig.DataDirPath,
		"TF_WORKSPACE": testTerraformConfig.Workspace,
		"foo":          "bar",
	}
	return cmd
}

func TestTerraformInit(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_init",
	})

	r := NewTestRunner(t)

	wantCmd := newTerraformTestCommand(
		"init", "-backend-config", testTerraformConfig.BackendConfigPath,
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Init(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestTerraformPlanNoDiff(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_plan_no_diff",
	})

	r := NewTestRunner(t)

	wantCmd := newTerraformTestCommand(
		"plan",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
		"-detailed-exitcode",
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.PlanNoDiff(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestTerraformPlanNoDiffDiff(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_plan_no_diff",
	})

	r := NewTestRunner(t)

	wantCmd := newTerraformTestCommand(
		"plan",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
		"-detailed-exitcode",
	)

	r.Push(&TestCommand{Command: wantCmd, ExitCode: 2})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.PlanNoDiff(); !errors.Is(err, TerraformPlanDiffErr) {
		t.Error("expected TerraformPlanDiffErr")
	}

	logTest.Diff(t)
}

func TestTerraformApply(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_apply",
		"terraform_apply",
	})

	r := NewTestRunner(t)

	wantCmd := newTerraformTestCommand(
		"apply",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Apply(false); err != nil {
		t.Error(err)
	}

	wantCmd = newTerraformTestCommand(
		"apply",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
		"-auto-approve",
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf = NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Apply(true); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestTerraformOutput(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_output",
	})

	r := NewTestRunner(t)

	var gotOutput string
	wantOutput := "not really terraform output"

	stdout, err := json.Marshal(wantOutput)
	if err != nil {
		t.Error(err)
	}

	wantCmd := newTerraformTestCommand(
		"output", "-json",
	)

	r.Push(&TestCommand{Command: wantCmd, Stdout: stdout})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Output(&gotOutput); err != nil {
		t.Error(err)
	}

	if wantOutput != gotOutput {
		t.Errorf("output mismatch, got: %s, want: %s", gotOutput, wantOutput)
	}

	logTest.Diff(t)
}

func TestTerraformDestroy(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"terraform_destroy",
		"terraform_destroy",
	})

	r := NewTestRunner(t)

	wantCmd := newTerraformTestCommand(
		"destroy",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf := NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Destroy(false); err != nil {
		t.Error(err)
	}

	wantCmd = newTerraformTestCommand(
		"destroy",
		"-var-file", "tfvars",
		"-target", testTerraformConfig.Target,
		"-auto-approve",
	)

	r.Push(&TestCommand{Command: wantCmd})

	tf = NewTerraform(logger, r, testTerraformConfig)

	if err := tf.Destroy(true); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}
