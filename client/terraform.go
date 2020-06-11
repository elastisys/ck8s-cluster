package client

import (
	"fmt"
	"os"

	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

func InitializeTerraformRemoteWorkspace(
	logger *zap.Logger,
	configHandler *ConfigHandler,
	cluster api.Cluster,
	backendConfig *api.TerraformBackendConfig,
	silent bool,
	autoApprove bool,
) error {
	logger.Info("init_terraform_remote_workspace")

	workspace := cluster.TerraformWorkspace()

	terraform := runner.NewTerraform(
		logger,
		runner.NewLocalRunner(logger, silent),
		&runner.TerraformConfig{
			Path:        configHandler.codePath[api.TerraformTFEDir].Path,
			Workspace:   workspace,
			DataDirPath: configHandler.configPath[api.TFEDataDir].Path,
			Env:         map[string]string{},
		},
	)

	dataDirPath := configHandler.configPath[api.TFDataDir].Path
	if err := os.MkdirAll(dataDirPath, 0755); err != nil {
		return fmt.Errorf("error creating dir %s: %w", dataDirPath, err)
	}

	if err := terraform.Init(); err != nil {
		return fmt.Errorf("error initializing TFE workspace: %w", err)
	}

	if err := terraform.Apply(
		autoApprove,
		"-var", "organization="+backendConfig.Organization,
		"-var", "workspace_name="+backendConfig.Workspaces.Prefix+workspace,
	); err != nil {
		return fmt.Errorf("error applying TFE workspace: %w", err)
	}

	return nil
}
