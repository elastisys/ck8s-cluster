package client

import (
	"bytes"
	"errors"
	"fmt"
	"io/ioutil"
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

	silent      bool
	autoApprove bool

	configPath api.ConfigPath
	codePath   api.CodePath

	sshPrivateKeyPath api.Path

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
	silent bool,
	autoApprove bool,
	configPath api.ConfigPath,
	codePath api.CodePath,
	terraformConfig *runner.TerraformConfig,
) *ClusterClient {
	localRunner := runner.NewLocalRunner(logger, silent)

	sshPrivateKeyPath := configPath[api.SSHPrivateKeyFile]

	sshAgentRunner := runner.NewSSHAgentRunner(
		logger,
		localRunner,
		sshPrivateKeyPath.Path,
	)

	return &ClusterClient{
		cluster: cluster,

		silent:      silent,
		autoApprove: autoApprove,

		configPath: configPath,
		codePath:   codePath,

		sshPrivateKeyPath: sshPrivateKeyPath,

		sops: runner.NewSOPS(
			logger,
			localRunner,
			configPath[api.SOPSConfigFile].Path,
		),

		s3cmd: runner.NewS3Cmd(
			logger,
			localRunner,
			string(cluster.CloudProvider()),
			configPath[api.S3CfgFile].Path,
			codePath[api.ManageS3BucketsScriptFile].Path,
			cluster.S3Buckets(),
		),

		terraform: runner.NewTerraform(
			logger,
			localRunner,
			terraformConfig,
		),

		ansible: runner.NewAnsible(
			logger,
			sshAgentRunner,
			codePath[api.AnsibleConfigFile].Path,
			configPath[api.AnsibleInventoryFile].Path,
			codePath[api.AnsiblePlaybookDeployKubernetesFile].Path,
			codePath[api.AnsiblePlaybookPrepareNodesFile].Path,
			codePath[api.AnsiblePlaybookJoinClusterFile].Path,
		),

		kubectl: runner.NewKubectl(
			logger,
			localRunner,
			configPath[api.KubeconfigFile].Path,
			cluster.Name(),
		),

		logger: logger,
	}
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

	if err := c.ansible.DeployKubernetes(
		c.configPath[api.KubeconfigFile].Path,
		c.codePath[api.CRDFile].Path,
	); err != nil {
		return fmt.Errorf("error joining cluster: %w", err)
	}

	return c.encryptKubeconfig()
}

// encryptKubeconfig encrypts the kubeconfig file.
// TODO: We should ideally never let the plaintext kubeconfig file touch the
// 		 file system. We could use the SSH runner and fetch the kubeconfig
//		 instead of using Ansible.
func (c *ClusterClient) encryptKubeconfig() error {
	kubeconfigPath := c.configPath[api.KubeconfigFile]

	if err := c.sops.EncryptFileInPlace(
		kubeconfigPath.Format,
		kubeconfigPath.Format,
		kubeconfigPath.Path,
	); err != nil {
		c.logger.Error(
			"client_apply_error_encrypting_kubeconfig",
			zap.Error(err),
		)

		c.logger.Info(
			"client_apply_delete_kubeconfig",
			zap.String("kubeconfig_path", kubeconfigPath.String()),
		)
		if err := os.Remove(kubeconfigPath.Path); err != nil {
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

	if err := c.renderS3cfg(); err != nil {
		return fmt.Errorf("error rendering s3 cfg: %w", err)
	}

	if err := c.s3cmd.Create(); err != nil {
		return fmt.Errorf("error creating S3 buckets: %w", err)
	}

	return nil
}

func (c *ClusterClient) renderS3cfg() error {
	var s3cfgPlain, s3cfgEnc bytes.Buffer

	if err := runner.RenderS3CfgPlaintext(c.cluster, &s3cfgPlain); err != nil {
		return fmt.Errorf("error rendering plaintext s3cfg: %w", err)
	}

	if err := c.sops.EncryptStdin(
		"ini",
		"ini",
		&s3cfgPlain,
		&s3cfgEnc,
	); err != nil {
		return fmt.Errorf("error encrypting s3cfg: %w", err)
	}

	if err := ioutil.WriteFile(
		c.configPath[api.S3CfgFile].Path,
		s3cfgEnc.Bytes(),
		0644,
	); err != nil {
		return fmt.Errorf("error writing s3cfg: %w", err)
	}

	return nil
}

func (c *ClusterClient) renderAnsibleInventory() error {
	c.logger.Info("client_render_ansible_inventory")

	state, err := c.state()
	if err != nil {
		return err
	}

	f, err := os.OpenFile(
		c.configPath[api.AnsibleInventoryFile].Path,
		os.O_WRONLY|os.O_CREATE|os.O_TRUNC,
		0666,
	)
	if err != nil {
		return fmt.Errorf("error opening file: %w", err)
	}
	if err := runner.RenderAnsibleInventory(c.cluster, state, f); err != nil {
		return fmt.Errorf("error rendering Ansible inventory: %w", err)
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

	c.logger.Info("client_terraform_apply2")

	if err := c.terraform.Apply(c.autoApprove); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	return c.renderAnsibleInventory()
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
	if err := c.saveTFVars(); err != nil {
		return fmt.Errorf("error saving tfvars: %w", err)
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

	if err := c.ResetNode(nodeType, name); err != nil {
		return fmt.Errorf("error resetting node: %w", err)
	}

	// TODO: handle machine already removed from tfvars
	if err := c.cluster.RemoveMachine(nodeType, name); err != nil {
		return fmt.Errorf("error removing machine: %w", err)
	}
	if err := c.saveTFVars(); err != nil {
		return fmt.Errorf("error saving tfvars: %w", err)
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

func (c *ClusterClient) saveTFVars() error {
	return ioutil.WriteFile(
		c.configPath[api.TFVarsFile].Path,
		tfvarsEncode(c.cluster.TFVars()),
		0644,
	)
}
