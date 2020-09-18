package runner

import (
	"go.uber.org/zap"
)

type AnsibleConfig struct {
	AnsibleConfigPath string
	InventoryPath     string

	PlaybookPathDeployKubernetes string
	PlaybookPathInfrastructure   string
	PlaybookPathPrepareNodes     string
	PlaybookPathJoinCluster      string

	KubeconfigPath string

	Env map[string]string
}

type Ansible struct {
	runner Runner

	config *AnsibleConfig

	logger *zap.Logger
}

func NewAnsible(
	logger *zap.Logger,
	runner Runner,
	config *AnsibleConfig,
) *Ansible {
	return &Ansible{
		runner: runner,

		config: config,

		logger: logger.With(
			zap.String("ansible_config", config.AnsibleConfigPath),
			zap.String("inventory", config.InventoryPath),
		),
	}
}

func (a *Ansible) playbook(playbookPath string, extraArgs ...string) *Command {
	a.logger.Debug("ansible_playbook", zap.String("playbook", playbookPath))

	args := []string{"-i", a.config.InventoryPath}
	args = append(args, extraArgs...)
	args = append(args, playbookPath)

	cmd := NewCommand("ansible-playbook", args...)

	cmd.Env = a.config.Env
	cmd.Env["ANSIBLE_CONFIG"] = a.config.AnsibleConfigPath

	return cmd
}

func (a *Ansible) AddEnv(env map[string]string) {
	for key, val := range env {
		a.config.Env[key] = val
	}
}

func (a *Ansible) Infrustructure() error {
	return a.runner.Run(a.playbook(a.config.PlaybookPathInfrastructure))
}

func (a *Ansible) DeployKubernetes() error {
	return a.runner.Run(a.playbook(
		a.config.PlaybookPathDeployKubernetes,
		"--extra-vars", "kubeconfig_path="+a.config.KubeconfigPath,
	))
}

func (a *Ansible) JoinCluster() error {
	err := a.runner.Run(a.playbook(a.config.PlaybookPathPrepareNodes))
	if err != nil {
		return err
	}
	return a.runner.Run(a.playbook(a.config.PlaybookPathJoinCluster))
}
