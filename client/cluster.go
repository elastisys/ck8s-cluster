package client

import (
	"errors"
	"fmt"
	"io"
	"os"
	"time"

	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

const (
	// newMachineSSHWaitTimeout is the maximum number of seconds to wait for
	// SSH after a new machine has been created.
	newMachineSSHWaitTimeout = 300 * time.Second
)

type ClusterClient struct {
	cluster api.Cluster

	configHandler *ConfigHandler

	silent      bool
	autoApprove bool

	sshPrivateKeyPath api.Path

	// TODO: Only needed because we need to encrypt the kubeconfig after it has
	//		 been created by the Ansible playbook.
	kubeconfigPath api.Path

	sops *runner.SOPS

	s3cmd *runner.S3Cmd

	terraform *runner.Terraform

	ansible *runner.Ansible

	kubectl *runner.Kubectl

	logger *zap.Logger
}

func NewClusterClient(
	logger *zap.Logger,
	cluster api.Cluster,
	configHandler *ConfigHandler,
	silent bool,
	autoApprove bool,
) (*ClusterClient, error) {
	sshPrivateKeyPath := configHandler.SSHPrivateKeyPath()

	localRunner := runner.NewLocalRunner(logger, silent)

	sshAgentRunner := runner.NewSSHAgentRunner(
		logger,
		localRunner,
		sshPrivateKeyPath.Path,
	)

	// TODO: Try to get rid of the error return.
	terraformConfig, err := configHandler.TerraformRunnerConfig(cluster)
	if err != nil {
		return nil, err
	}

	return &ClusterClient{
		cluster: cluster,

		configHandler: configHandler,

		silent:      silent,
		autoApprove: autoApprove,

		sshPrivateKeyPath: sshPrivateKeyPath,

		kubeconfigPath: configHandler.KubeconfigPath(),

		sops: runner.NewSOPS(
			logger,
			localRunner,
			configHandler.SOPSRunnerConfig(),
		),

		s3cmd: runner.NewS3Cmd(
			logger,
			localRunner,
			configHandler.S3CmdRunnerConfig(cluster),
		),

		terraform: runner.NewTerraform(
			logger,
			localRunner,
			terraformConfig,
		),

		ansible: runner.NewAnsible(
			logger,
			sshAgentRunner,
			configHandler.AnsibleRunnerConfig(cluster),
		),

		kubectl: runner.NewKubectl(
			logger,
			localRunner,
			configHandler.KubectlRunnerConfig(cluster),
		),

		logger: logger,
	}, nil
}

func (c *ClusterClient) MachineClient(m api.MachineState) *MachineClient {
	return NewMachineClient(
		c.logger,
		c.silent,
		m,
		c.sshPrivateKeyPath,
	)
}

func (c *ClusterClient) Apply() error {
	c.logger.Info("client_apply")

	if err := c.s3Apply(); err != nil {
		return err
	}

	if err := c.TerraformApply(); err != nil {
		return err
	}

	machines, err := c.Machines()
	if err != nil {
		return fmt.Errorf("error getting machines: %w", err)
	}

	for _, machine := range machines {
		if err := c.WaitForSSH(machine); err != nil {
			return err
		}
	}

	if c.cluster.CloudProvider() == api.Safespring ||
		c.cluster.CloudProvider() == api.CityCloud {
		if err := c.ansible.Infrustructure(); err != nil {
			return fmt.Errorf("error infrastructure: %w", err)
		}
	}

	if err := c.ansible.DeployKubernetes(); err != nil {
		return fmt.Errorf("error joining cluster: %w", err)
	}

	return c.encryptKubeconfig()
}

// encryptKubeconfig encrypts the kubeconfig file.
// TODO: We should ideally never let the plaintext kubeconfig file touch the
// 		 file system. We could use the SSH runner and fetch the kubeconfig
//		 instead of using Ansible.
func (c *ClusterClient) encryptKubeconfig() error {
	if err := c.sops.EncryptFileInPlace(
		c.kubeconfigPath.Format,
		c.kubeconfigPath.Format,
		c.kubeconfigPath.Path,
	); err != nil {
		c.logger.Error(
			"client_apply_error_encrypting_kubeconfig",
			zap.Error(err),
		)

		c.logger.Info(
			"client_apply_delete_kubeconfig",
			zap.String("kubeconfig_path", c.kubeconfigPath.String()),
		)
		if err := os.Remove(c.kubeconfigPath.Path); err != nil {
			c.logger.Error(
				"client_apply_error_deleting_kubeconfig",
				zap.Error(err),
			)
		}

		return fmt.Errorf("error encrypting kubeconfig: %w", err)
	}

	return nil
}

func (c *ClusterClient) state() (api.ClusterState, error) {
	return c.cluster.State(c.TerraformOutput)
}

// s3Apply renders the s3cfg file and creates the S3 buckets.
func (c *ClusterClient) s3Apply() error {
	c.logger.Info("client_s3_apply")

	if err := c.configHandler.WriteS3cfg(
		c.cluster,
		func(format string, plain io.Reader, enc io.Writer) error {
			return c.sops.EncryptStdin(format, format, plain, enc)
		},
	); err != nil {
		return fmt.Errorf("error writing s3cfg: %w", err)
	}

	if err := c.s3cmd.Create(); err != nil {
		return fmt.Errorf("error creating S3 buckets: %w", err)
	}

	return nil
}

// TerraformApply apples the Terraform configuration and updates the Ansible
// inventory.
func (c *ClusterClient) TerraformApply() error {
	c.logger.Info("client_terraform_apply")

	if err := c.terraform.Init(); err != nil {
		return err
	}

	if err := c.terraform.Apply(c.autoApprove); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	if err := c.configHandler.WriteAnsibleInventory(
		c.cluster,
		c.state,
	); err != nil {
		return fmt.Errorf("error writing Ansible inventory: %w", err)
	}

	return nil
}

func (c *ClusterClient) TerraformOutput(output interface{}) error {
	c.logger.Info("client_terraform_output")

	if err := c.terraform.Init(); err != nil {
		return err
	}

	return c.terraform.Output(output)
}

func (c *ClusterClient) Machines() ([]api.MachineState, error) {
	c.logger.Info("client_machine_list")

	state, err := c.state()
	if err != nil {
		return nil, err
	}

	return state.Machines(), nil
}

func (c *ClusterClient) Machine(
	nodeType api.NodeType,
	name string,
) (api.MachineState, error) {
	c.logger.Info(
		"client_machine",
		zap.String("node_type", nodeType.String()),
		zap.String("name", name),
	)

	state, err := c.state()
	if err != nil {
		return api.MachineState{}, err
	}

	return state.Machine(nodeType, name)
}

func (c *ClusterClient) CloneNode(
	nodeType api.NodeType,
	name string,
) error {
	c.logger.Info(
		"client_node_clone",
		zap.String("node_type", nodeType.String()),
		zap.String("name", name),
	)

	cloneName, err := c.cluster.CloneMachine(nodeType, name)
	if err != nil {
		return fmt.Errorf("error cloning machine: %w", err)
	}
	if err := c.configHandler.WriteTFVars(c.cluster); err != nil {
		return fmt.Errorf("error writing tfvars: %w", err)
	}

	if err := c.Apply(); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	machine, err := c.Machine(nodeType, cloneName)
	if err != nil {
		return fmt.Errorf("error getting machine: %w", err)
	}

	if err := c.WaitForSSH(machine); err != nil {
		return err
	}

	if err := c.ansible.JoinCluster(); err != nil {
		return fmt.Errorf("error joining cluster: %w", err)
	}

	return nil
}

func (c *ClusterClient) WaitForSSH(machine api.MachineState) error {
	machineClient := c.MachineClient(machine)

	if err := machineClient.WaitForSSH(newMachineSSHWaitTimeout); err != nil {
		return err
	}

	return nil
}

func (c *ClusterClient) DrainNode(name string) error {
	c.logger.Info(
		"client_node_drain",
		zap.String("name", name),
	)

	return c.kubectl.Drain(name)
}

func (c *ClusterClient) nodeExists(name string) (bool, error) {
	if err := c.kubectl.NodeExists(name); err != nil {
		if errors.Is(err, runner.NodeNotFoundErr) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func (c *ClusterClient) ResetNode(nodeType api.NodeType, name string) error {
	machine, err := c.Machine(nodeType, name)
	if err != nil {
		return fmt.Errorf("error getting machine: %w", err)
	}

	// TODO: machine already reseted
	if err := c.MachineClient(machine).Reset(); err != nil {
		return err
	}

	return c.kubectl.DeleteNode(name)
}

func (c *ClusterClient) RemoveNode(nodeType api.NodeType, name string) error {
	logger := c.logger.With(
		zap.String("node_type", nodeType.String()),
		zap.String("name", name),
	)

	logger.Info("client_node_remove")

	nodeExists, err := c.nodeExists(name)
	if err != nil {
		return fmt.Errorf("error checking node existence: %w", err)
	}

	if nodeExists {
		if err := c.DrainNode(name); err != nil {
			return err
		}
	} else {
		logger.Warn("client_node_remove_node_not_found")
	}

	// TODO: Do not throw error if the node hasn't joined k8s
	if err := c.ResetNode(nodeType, name); err != nil {
		return fmt.Errorf("error resetting node: %w", err)
	}

	// TODO: handle machine already removed from tfvars
	if err := c.cluster.RemoveMachine(nodeType, name); err != nil {
		return fmt.Errorf("error removing machine: %w", err)
	}
	if err := c.configHandler.WriteTFVars(c.cluster); err != nil {
		return fmt.Errorf("error writing tfvars: %w", err)
	}

	if err := c.TerraformApply(); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	if nodeExists {
		c.kubectl.DeleteNode(name)
	}

	return nil
}

func (c *ClusterClient) ReplaceNode(nodeType api.NodeType, name string) error {
	c.logger.Info(
		"client_node_replace",
		zap.String("node_type", nodeType.String()),
		zap.String("name", name),
	)
	if err := c.terraform.Init(); err != nil {
		return err
	}

	if err := c.terraform.PlanNoDiff(); err != nil {
		if errors.Is(err, runner.TerraformPlanDiffErr) {
			return err
		}
		return fmt.Errorf("error checking if Terraform plan has diff: %w", err)
	}

	if err := c.CloneNode(nodeType, name); err != nil {
		return err
	}

	if err := c.RemoveNode(nodeType, name); err != nil {
		return err
	}

	return nil
}
