package client

import (
	"errors"
	"fmt"
	"io"
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

	configHandler *ConfigHandler

	silent      bool
	autoApprove bool

	sshPrivateKeyPath api.Path

	// TODO: Only needed because we need to encrypt the kubeconfig after it has
	//		 been created by the Ansible playbook.
	kubeconfigPath api.Path

	sops *runner.SOPS

	s3cmd *runner.S3Cmd

	tfe *runner.Terraform

	terraform *runner.Terraform

	ansible *runner.Ansible

	kubectl *runner.Kubectl

	logger *zap.Logger
}

func NewClusterClient(
	logger *zap.Logger,
	cluster api.Cluster,
	configHandler *ConfigHandler,
	localRunner runner.Runner,
	silent bool,
	autoApprove bool,
) (*ClusterClient, error) {
	sshPrivateKeyPath := configHandler.SSHPrivateKeyPath()

	sshAgentRunner := runner.NewSSHAgentRunner(
		logger,
		localRunner,
		sshPrivateKeyPath.Path,
	)

	// TODO: Try to get rid of the error return.
	tfeConfig, err := configHandler.TFETerraformRunnerConfig()
	if err != nil {
		return nil, err
	}
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

		tfe: runner.NewTerraform(
			logger,
			localRunner,
			tfeConfig,
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

// Apply applies the Terraform remote workspace configuration as well as the
// cluster Terraform configuration. It then waits for any newly created machine
// to become active and finishes by running the Ansible playbook
// `deploy-kubernetes` which, among other things, initializes the Kubernetes
// cluster and joins all the nodes.
//
// The Apply function is used both to bootstrap an entirely new cluster as well
// as applying new changes in the configuration.
func (c *ClusterClient) Apply() error {
	c.logger.Info("client_apply")

	if err := c.terraformRemoteWorkspaceApply(); err != nil {
		return err
	}

	if err := c.S3Apply(); err != nil {
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
		if err := c.waitForNewMachine(machine); err != nil {
			return err
		}
	}

	currentState, err := c.state()
	if err != nil {
		return fmt.Errorf("error getting cluster state: %w", err)
	}
	c.ansible.AddEnv(map[string]string{
		"ECK_BASE_DOMAIN": currentState.BaseDomain(),
	})

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

// Join is similar to Apply except that it only focuses on a single node. It
// applies the Terraform configuration and waits for the machine. Finally it
// runs the Ansible playbook `join-cluster` which joins new machines to
// Kubernetes.
//
// The Join function is useful when adding, cloning or replacing a single node.
func (c *ClusterClient) Join(name string) (api.MachineState, error) {
	c.logger.Info("client_join")

	if err := c.TerraformApply(); err != nil {
		return api.MachineState{}, fmt.Errorf(
			"error applying Terraform config: %w", err,
		)
	}

	machineState, err := c.Machine(name)
	if err != nil {
		return machineState, fmt.Errorf("error getting machine: %w", err)
	}
	if err := c.waitForNewMachine(machineState); err != nil {
		return machineState, err
	}

	if err := c.ansible.JoinCluster(); err != nil {
		return machineState, fmt.Errorf("error joining cluster: %w", err)
	}

	return machineState, nil
}

func (c *ClusterClient) Destroy(deleteRemoteWorkspace bool, kubernetesCleanup bool) error {
	c.logger.Info("client_destroy")

	// Best effort to clean up volumes and loadbalancer
	if kubernetesCleanup && c.kubectl.IsUp() {
		c.kubectl.DeleteAll("persistentvolumeclaims", "--timeout=5s")

		// TODO Make smarter that to delete all pods, try to delete only once with pvc
		c.kubectl.DeleteAll("pod", "--grace-period=60")

		if err := c.kubectl.DeleteAll("service"); err != nil {
			return fmt.Errorf("error deleting persistent volume claims: %w", err)
		}
	}

	if err := c.TerraformDestroy(); err != nil {
		return fmt.Errorf("error destroying Terraform resources: %w", err)
	}

	if err := c.S3Delete(); err != nil {
		return err
	}

	if deleteRemoteWorkspace {
		if err := c.terraformRemoteWorkspaceDestroy(); err != nil {
			return err
		}
	}

	return nil
}

// ConfiguredMachines returns a map of machines in the configuration.
func (c *ClusterClient) ConfiguredMachines() map[string]*api.Machine {
	c.logger.Info("client_configured_machines")
	return c.cluster.Machines()
}

// Machines returns a map of machines currently in the cluster state.
func (c *ClusterClient) Machines() (map[string]api.MachineState, error) {
	c.logger.Info("client_current_machines")

	state, err := c.state()
	if err != nil {
		return nil, err
	}

	return state.Machines(), nil
}

// Machine returns a machine if it exists in the cluster state.
func (c *ClusterClient) Machine(name string) (api.MachineState, error) {
	c.logger.Info(
		"client_current_machine",
		zap.String("name", name),
	)

	state, err := c.state()
	if err != nil {
		return api.MachineState{}, err
	}

	return state.Machine(name)
}

// AddMachine adds a new machine to the cluster configuration.
func (c *ClusterClient) AddMachine(
	name string,
	nodeType api.NodeType,
	size string,
	image string,
	providerSettings map[string]interface{},
) (string, error) {
	c.logger.Info(
		"client_machine_add",
		zap.String("name", name),
		zap.String("node_type", string(nodeType)),
		zap.String("size", size),
		zap.String("image", image),
		// TODO: Log provider settings
	)

	if err := c.TerraformPlanNoDiff(); err != nil {
		return "", err
	}

	cloudProvider, err := CloudProviderFromType(c.cluster.CloudProvider())
	if err != nil {
		return "", err
	}

	machineFactory := api.NewMachineFactory(cloudProvider, nodeType, size)

	if image != "" {
		machineFactory.WithImage(image)
	}

	if providerSettings != nil {
		machineFactory.WithProviderSettings(providerSettings)
	}

	machine, err := machineFactory.Build()
	if err != nil {
		return "", fmt.Errorf("error building machine: %w", err)
	}

	return c.cluster.AddMachine(name, machine)
}

func (c *ClusterClient) CloneMachine(
	name string,
	image string,
) (string, error) {
	c.logger.Info(
		"client_machine_clone",
		zap.String("name", name),
		zap.String("image", image),
	)

	if err := c.TerraformPlanNoDiff(); err != nil {
		return "", err
	}

	machine, ok := c.ConfiguredMachines()[name]
	if !ok {
		return "", fmt.Errorf(
			"error machine not found: %s", name,
		)
	}

	if image != "" {
		cloudProvider, err := CloudProviderFromType(c.cluster.CloudProvider())
		if err != nil {
			return "", err
		}

		machineFactory := api.NewMachineFactoryFromExistingMachine(
			cloudProvider,
			machine,
		)

		machine, err = machineFactory.WithImage(image).Build()
		if err != nil {
			return "", fmt.Errorf("error building machine: %w", err)
		}
	}

	return c.cluster.AddMachine("", machine)
}

func (c *ClusterClient) DrainNode(name string) error {
	c.logger.Info(
		"client_node_drain",
		zap.String("name", name),
	)

	return c.kubectl.Drain(name)
}

func (c *ClusterClient) NodeExists(name string) (bool, error) {
	c.logger.Info("client_node_exists", zap.String("name", name))

	if err := c.kubectl.NodeExists(name); err != nil {
		if errors.Is(err, runner.NodeNotFoundErr) {
			return false, nil
		}
		return false, err
	}

	return true, nil
}

func (c *ClusterClient) ResetNode(name string) error {
	machine, err := c.Machine(name)
	if err != nil {
		return fmt.Errorf("error getting machine: %w", err)
	}

	// TODO: machine already reseted
	if err := c.MachineClient(machine).Reset(); err != nil {
		return err
	}

	return c.kubectl.DeleteNode(name)
}

func (c *ClusterClient) RemoveNode(name string) error {
	logger := c.logger.With(
		zap.String("name", name),
	)

	logger.Info("client_node_remove")

	// Make sure no changes are already pending.
	if err := c.TerraformPlanNoDiff(); err != nil {
		return err
	}

	nodeExists, err := c.NodeExists(name)
	if err != nil {
		return fmt.Errorf("error checking node existence: %w", err)
	}

	// Drain the node.
	if nodeExists {
		if err := c.DrainNode(name); err != nil {
			return err
		}
	} else {
		logger.Warn("client_node_remove_node_not_found")
	}

	// Reset the machine.
	// TODO: Do not throw error if the node hasn't joined k8s
	if err := c.ResetNode(name); err != nil {
		return fmt.Errorf("error resetting node: %w", err)
	}

	// Remove the machine.
	// TODO: handle machine already removed from tfvars
	if err := c.cluster.RemoveMachine(name); err != nil {
		return fmt.Errorf("error removing machine: %w", err)
	}
	if err := c.TerraformApply(); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	// Delete the node from Kubernetes.
	if nodeExists {
		c.kubectl.DeleteNode(name)
	}

	return nil
}

// S3Apply renders the s3cfg file and creates the S3 buckets.
func (c *ClusterClient) S3Apply() error {
	c.logger.Info("client_s3_apply")

	if err := c.s3WriteConfig(); err != nil {
		return err
	}

	if err := c.s3cmd.Create(); err != nil {
		return fmt.Errorf("error creating S3 buckets: %w", err)
	}

	return nil
}

func (c *ClusterClient) S3Delete() error {
	c.logger.Debug("client_s3_delete")

	if err := c.s3WriteConfig(); err != nil {
		return err
	}

	if err := c.s3cmd.Abort(); err != nil {
		return fmt.Errorf("error aborting multipart S3 uploads")
	}

	if err := c.s3cmd.Delete(); err != nil {
		return fmt.Errorf("error deleting S3 buckets")
	}

	return nil
}

// TerraformApply applies the Terraform configuration and updates the Ansible
// inventory.
func (c *ClusterClient) TerraformApply() error {
	c.logger.Info("client_terraform_apply")

	if err := c.configHandler.WriteTFVars(c.cluster); err != nil {
		return fmt.Errorf("error writing tfvars: %w", err)
	}

	if err := c.terraform.Init(); err != nil {
		return err
	}

	if err := c.terraform.Apply(c.autoApprove); err != nil {
		return fmt.Errorf("error applying Terraform config: %w", err)
	}

	// TODO REMOVE as soon as ck8s-apps doesn't depend on this
	var tfOutput interface{}
	if err := c.terraform.Output(&tfOutput); err != nil {
		return fmt.Errorf("error outputting Terraform config: %w", err)
	}
	if err := c.configHandler.WriteInfraJSON(c.cluster, c.state, tfOutput); err != nil {
		return fmt.Errorf("error writing infra inventory: %w", err)
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

func (c *ClusterClient) TerraformDestroy() error {
	c.logger.Info("client_terraform_destroy")

	if err := c.terraform.Init(); err != nil {
		return err
	}

	if err := c.terraform.Destroy(c.autoApprove); err != nil {
		return fmt.Errorf("error destroying Terraform resources: %w", err)
	}

	return nil
}

func (c *ClusterClient) TerraformPlanNoDiff() error {
	c.logger.Info("client_terraform_plan_no_diff")

	if err := c.terraform.Init(); err != nil {
		return err
	}

	if err := c.terraform.PlanNoDiff(); err != nil {
		if errors.Is(err, runner.TerraformPlanDiffErr) {
			return err
		}
		return fmt.Errorf("error checking if Terraform plan has diff: %w", err)
	}

	return nil
}

func (c *ClusterClient) Kubectl(args []string) error {
	return c.kubectl.Command(args)
}

func (c *ClusterClient) state() (api.ClusterState, error) {
	return c.cluster.State(c.TerraformOutput)
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

func (c *ClusterClient) readTerraformBackendConfig() (api.TerraformBackendConfig, error) {
	var backendConfig api.TerraformBackendConfig

	f, err := os.Open(c.configHandler.configPath[api.TFBackendConfigFile].Path)
	if err != nil {
		return backendConfig, fmt.Errorf("error opening file: %w", err)
	}

	backendConfigBytes, err := ioutil.ReadAll(f)
	if err != nil {
		return backendConfig, fmt.Errorf("error reading file: %w", err)
	}

	if len(backendConfigBytes) > 0 {
		if err := hclDecode(backendConfigBytes, &backendConfig); err != nil {
			return backendConfig, fmt.Errorf("error can't decode terraform backend: %w", err)
		}
	}

	return backendConfig, nil
}

func (c *ClusterClient) terraformRemoteWorkspaceApply() error {
	c.logger.Debug("client_terraform_remote_workspace_apply")

	dataDirPath := c.configHandler.configPath[api.TFDataDir].Path
	if err := os.MkdirAll(dataDirPath, 0755); err != nil {
		return fmt.Errorf("error creating dir %s: %w", dataDirPath, err)
	}

	if err := c.tfe.Init(); err != nil {
		return fmt.Errorf("error initializing TFE workspace: %w", err)
	}

	backendConfig, err := c.readTerraformBackendConfig()
	if err != nil {
		return fmt.Errorf("error reading terraform backend config: %w", err)
	}
	workspace := c.cluster.TerraformWorkspace()

	if err := c.tfe.Apply(
		c.autoApprove,
		"-var", "organization="+backendConfig.Organization,
		"-var", "workspace_name="+backendConfig.Workspaces.Prefix+workspace,
	); err != nil {
		return fmt.Errorf("error applying TFE remote workspace: %w", err)
	}

	return nil
}

func (c *ClusterClient) terraformRemoteWorkspaceDestroy() error {
	c.logger.Debug("client_terraform_remote_workspace_destroy")

	if err := c.tfe.Init(); err != nil {
		return fmt.Errorf("error initializing TFE workspace: %w", err)
	}

	backendConfig, err := c.readTerraformBackendConfig()
	if err != nil {
		return fmt.Errorf("error reading terraform backend config: %w", err)
	}
	workspace := c.cluster.TerraformWorkspace()

	if err := c.tfe.Destroy(
		c.autoApprove,
		"-var", "organization="+backendConfig.Organization,
		"-var", "workspace_name="+backendConfig.Workspaces.Prefix+workspace,
	); err != nil {
		return fmt.Errorf("error destroying the remote workspace")
	}

	return nil
}

func (c *ClusterClient) s3WriteConfig() error {
	if err := c.configHandler.WriteS3cfg(
		c.cluster,
		func(format string, plain io.Reader, enc io.Writer) error {
			return c.sops.EncryptStdin(format, format, plain, enc)
		},
	); err != nil {
		return fmt.Errorf("error writing s3cfg: %w", err)
	}

	return nil
}

func (c *ClusterClient) waitForNewMachine(machine api.MachineState) error {
	machineClient := c.MachineClient(machine)

	if err := machineClient.WaitForSSH(newMachineSSHWaitTimeout); err != nil {
		return err
	}

	return nil
}
