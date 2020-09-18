package runner

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"io/ioutil"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var TerraformPlanDiffErr = errors.New("terraform plan has diff")

type TerraformConfig struct {
	Path        string
	Workspace   string
	DataDirPath string
	// TODO: This is only necessary when using local backend since TF_DATA_DIR
	//		 does not seem to be considered in that case for some reason.
	StatePath         string
	BackendConfigPath string
	TFVarsPath        string

	// TODO: If we switch over to a single cluster implementation target should
	//		 become unnecessary.
	Target string

	// TODO: We should try to get rid of this.
	Env map[string]string
}

func (c *TerraformConfig) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("path", c.Path)
	enc.AddString("workspace", c.Workspace)
	enc.AddString("data_dir", c.DataDirPath)
	enc.AddString("state", c.StatePath)
	enc.AddString("backend_config", c.BackendConfigPath)
	enc.AddString("tfvars", c.TFVarsPath)
	return nil
}

type Terraform struct {
	runner Runner

	config *TerraformConfig

	logger *zap.Logger
}

func NewTerraform(
	logger *zap.Logger,
	runner Runner,
	config *TerraformConfig,
) *Terraform {
	return &Terraform{
		runner: runner,

		config: config,

		logger: logger.With(
			zap.Object("config", config),
		),
	}
}

func (t *Terraform) command(args ...string) *Command {
	cmd := NewCommand("terraform", args...)

	cmd.Env = t.config.Env
	cmd.Env["TF_DATA_DIR"] = t.config.DataDirPath
	cmd.Env["TF_WORKSPACE"] = t.config.Workspace

	// Some Terraform commands allows you to supply the configuration path as
	// an argument, some don't. For now let's change working directory for the
	// command. It shouldn't matter as long as we don't share instances.
	// If we ever want to control multiple Terraform configuration paths
	// with the same command instance see:
	// https://github.com/hashicorp/terraform/issues/15761
	// https://github.com/hashicorp/terraform/issues/15581
	// https://github.com/hashicorp/terraform/issues/15934
	// https://github.com/hashicorp/terraform/issues/17300
	cmd.Dir = t.config.Path

	return cmd
}

// Init runs `terraform init` optionally with the `-backend-config` flag if a
// backend config path is configured.
func (t *Terraform) Init() error {
	t.logger.Debug("terraform_init")
	args := []string{"init"}
	if t.config.BackendConfigPath != "" {
		args = append(
			args,
			[]string{"-backend-config", t.config.BackendConfigPath}...,
		)
	}
	return t.runner.Background(t.command(args...))
}

// HasNoDiff runs `terraform plan -detailed-exitcode` and returns an error of
// type TerraformPlanDiffErr if it has a diff. It optionally runs with the
// flags `-var-file` and `-target` if either is configured.
func (t *Terraform) PlanNoDiff() error {
	t.logger.Debug("terraform_plan_no_diff")

	args := []string{"plan"}
	if t.config.TFVarsPath != "" {
		args = append(args, []string{"-var-file", t.config.TFVarsPath}...)
	}
	if t.config.Target != "" {
		args = append(args, []string{"-target", t.config.Target}...)
	}
	if t.config.StatePath != "" {
		args = append(args, []string{"-state", t.config.StatePath}...)
	}
	args = append(args, "-detailed-exitcode")

	cmd := t.command(args...)

	// A second diff check, which looks for "0 to add, 0 to change, 0 to
	// destroy", is required since data sources with a `depends_on` is always
	// evaluated even though no diff actually exist. This seems to be fixed in
	// Terraform v0.13.
	/// https://github.com/hashicorp/terraform/issues/11806
	// TOOD: Remove output handler and second diff check when we have upgraded
	// to Terraform v0.13.
	var output []byte
	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		var err error
		output, err = ioutil.ReadAll(stdout)
		return err
	}
	cmd.ExitCodeHandlers[2] = func() error {
		secondDiffCheck := []byte("0 to add, 0 to change, 0 to destroy")
		if bytes.Index(output, secondDiffCheck) != -1 {
			return nil
		}

		return TerraformPlanDiffErr
	}

	return t.runner.Run(cmd)
}

// Apply runs `terraform apply` with the -auto-approve flag if autoApprove is
// true. If autoApprove is false it always outputs to allow for interactive
// input. It optionally runs with the flags `-var-file` and `-target` if
// either is configured.
func (t *Terraform) Apply(autoApprove bool, extraArgs ...string) error {
	t.logger.Debug("terraform_apply")

	args := []string{"apply"}
	if t.config.TFVarsPath != "" {
		args = append(args, []string{"-var-file", t.config.TFVarsPath}...)
	}
	if t.config.Target != "" {
		args = append(args, []string{"-target", t.config.Target}...)
	}
	if t.config.StatePath != "" {
		args = append(args, []string{"-state", t.config.StatePath}...)
	}
	if autoApprove {
		args = append(args, "-auto-approve")
	}

	cmd := t.command(append(args, extraArgs...)...)

	if !autoApprove {
		return t.runner.Output(cmd)
	}

	return t.runner.Run(cmd)
}

// Output runs `terraform output -json` in the background and stores the output
// in the output value.
func (t *Terraform) Output(output interface{}) error {
	t.logger.Debug("terraform_output")

	args := []string{"output", "-json"}

	if t.config.StatePath != "" {
		args = append(args, []string{"-state", t.config.StatePath}...)
	}

	cmd := t.command(args...)

	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		return json.NewDecoder(stdout).Decode(&output)
	}

	return t.runner.Background(cmd)
}

// Destroy runs `terraform destroy`. with the -auto-approve flag if
// autoApprove is true. If autoApprove is false it always outputs to allow for
// interactive input. It optionally runs with the flags `-var-file` and
// `-target` if either is configured.
func (t *Terraform) Destroy(autoApprove bool, extraArgs ...string) error {
	t.logger.Debug("terraform_destroy")

	args := []string{"destroy"}
	if t.config.TFVarsPath != "" {
		args = append(args, []string{"-var-file", t.config.TFVarsPath}...)
	}
	if t.config.Target != "" {
		args = append(args, []string{"-target", t.config.Target}...)
	}
	if t.config.StatePath != "" {
		args = append(args, []string{"-state", t.config.StatePath}...)
	}
	if autoApprove {
		args = append(args, "-auto-approve")
	}

	cmd := t.command(append(args, extraArgs...)...)

	if !autoApprove {
		return t.runner.Output(cmd)
	}

	return t.runner.Run(cmd)
}
