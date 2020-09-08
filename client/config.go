package client

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/spf13/viper"
	"go.mozilla.org/sops/v3/decrypt"
	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

type ConfigHandler struct {
	clusterType api.ClusterType
	configPath  api.ConfigPath
	codePath    api.CodePath

	logger *zap.Logger
}

func NewConfigHandler(
	logger *zap.Logger,
	clusterType api.ClusterType,
	configPath api.ConfigPath,
	codePath api.CodePath,
) *ConfigHandler {
	return &ConfigHandler{
		clusterType: clusterType,
		configPath:  configPath,
		codePath:    codePath,

		logger: logger,
	}
}

// Read parses the config path, validates the configuration and returns a
// cluster.
func (c *ConfigHandler) Read() (api.Cluster, error) {
	cluster, err := c.readConfig()
	if err != nil {
		return nil, fmt.Errorf("error parsing config: %w", err)
	}

	if err = c.readSecrets(cluster); err != nil {
		return nil, fmt.Errorf("error parsing secrets: %w", err)
	}

	if err := c.readTFVars(cluster); err != nil {
		return nil, fmt.Errorf("error parsing tfvars: %w", err)
	}

	if err := api.ValidateCluster(cluster); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return cluster, nil
}

// WriteTFVars validates the cluster configuration and saves only the Terraform
// variables part of the config path.
func (c *ConfigHandler) WriteTFVars(cluster api.Cluster) error {
	if err := api.ValidateCluster(cluster); err != nil {
		return fmt.Errorf("config validation failed: %w", err)
	}

	return c.writeTFVars(cluster)
}

func (c *ConfigHandler) WriteS3cfg(
	cluster api.Cluster,
	encryptFn func(format string, plain io.Reader, enc io.Writer) error,
) error {
	c.logger.Debug("config_handler_s3cfg_write")

	var s3cfgPlain, s3cfgEnc bytes.Buffer

	s3cfgPath := c.configPath[api.S3CfgFile]

	if err := renderS3CfgPlaintext(cluster, &s3cfgPlain); err != nil {
		return fmt.Errorf("error rendering plaintext s3cfg: %w", err)
	}

	if err := encryptFn(s3cfgPath.Format, &s3cfgPlain, &s3cfgEnc); err != nil {
		return fmt.Errorf("error encrypting s3cfg: %w", err)
	}

	if err := ioutil.WriteFile(
		s3cfgPath.Path,
		s3cfgEnc.Bytes(),
		0644,
	); err != nil {
		return fmt.Errorf("error writing s3cfg: %w", err)
	}

	return nil
}

func (c *ConfigHandler) WriteAnsibleInventory(
	cluster api.Cluster,
	stateFn func() (api.ClusterState, error),
) error {
	// c.logger.Info("client_render_ansible_inventory")

	f, err := os.OpenFile(
		c.configPath[api.AnsibleInventoryFile].Path,
		os.O_WRONLY|os.O_CREATE|os.O_TRUNC,
		0644,
	)
	if err != nil {
		return fmt.Errorf("error opening file: %w", err)
	}

	state, err := stateFn()
	if err != nil {
		return fmt.Errorf("error getting cluster state: %w", err)
	}

	if err := renderAnsibleInventory(cluster, state, f); err != nil {
		return fmt.Errorf("error rendering Ansible inventory: %w", err)
	}

	return nil
}

func (c *ConfigHandler) TerraformRunnerConfig(
	cluster api.Cluster,
) (*runner.TerraformConfig, error) {
	var tfPath api.Path
	var tfTarget string

	switch cloudProvider := cluster.CloudProvider(); cloudProvider {
	case api.Exoscale:
		tfPath = c.codePath[api.TerraformExoscaleDir]

		switch c.clusterType {
		case api.ServiceCluster:
			tfTarget = "module.service_cluster"
		case api.WorkloadCluster:
			tfTarget = "module.workload_cluster"
		}
	case api.Safespring:
		tfPath = c.codePath[api.TerraformSafespringDir]

		switch c.clusterType {
		case api.ServiceCluster:
			tfTarget = "module.service_cluster"
		case api.WorkloadCluster:
			tfTarget = "module.workload_cluster"
		}
	case api.CityCloud:
		tfPath = c.codePath[api.TerraformCityCloudDir]

		switch c.clusterType {
		case api.ServiceCluster:
			tfTarget = "module.service_cluster"
		case api.WorkloadCluster:
			tfTarget = "module.workload_cluster"
		}
	case api.AWS:
		tfPath = c.codePath[api.TerraformAWSDir]

		switch c.clusterType {
		case api.ServiceCluster:
			tfTarget = "module.service_cluster"
		case api.WorkloadCluster:
			tfTarget = "module.workload_cluster"
		}
	case api.Azure:
		tfPath = c.codePath[api.TerraformAzureDir]

		switch c.clusterType {
		case api.ServiceCluster:
			tfTarget = "module.service_cluster"
		case api.WorkloadCluster:
			tfTarget = "module.workload_cluster"
		}
	default:
		return nil, api.NewUnsupportedCloudProviderError(cloudProvider)
	}

	// TODO: Find a nicer solution to this.
	if err := tfPath.Exists(); err != nil {
		if errors.Is(err, api.PathNotFoundErr) {
			return nil, fmt.Errorf(
				"terraform path not found: %s\nwrong CK8S code path?",
				tfPath.Path,
			)
		}
		return nil, err
	}

	tfEnv := cluster.TerraformEnv(c.configPath[api.SSHPublicKeyFile].Path)

	return &runner.TerraformConfig{
		Path:              tfPath.Path,
		Workspace:         cluster.TerraformWorkspace(),
		DataDirPath:       c.configPath[api.TFDataDir].Path,
		BackendConfigPath: c.configPath[api.TFBackendConfigFile].Path,
		TFVarsPath:        c.configPath[api.TFVarsFile].Path,

		Target: tfTarget,

		Env: tfEnv,
	}, nil
}

func (c *ConfigHandler) TFETerraformRunnerConfig() (*runner.TerraformConfig, error) {
	tfModulePath := c.codePath[api.TerraformTFEDir]

	// TODO: Find a nicer solution to this.
	if err := tfModulePath.Exists(); err != nil {
		if errors.Is(err, api.PathNotFoundErr) {
			return nil, fmt.Errorf(
				"tfe module path not found: %s\nwrong CK8S code path?",
				tfModulePath.Path,
			)
		}
		return nil, err
	}

	return &runner.TerraformConfig{
		Path:        tfModulePath.Path,
		StatePath:   c.configPath[api.TFEStateFile].Path,
		DataDirPath: c.configPath[api.TFEDataDir].Path,
		Env:         map[string]string{},
	}, nil
}

func (c *ConfigHandler) AnsibleRunnerConfig(
	cluster api.Cluster,
) *runner.AnsibleConfig {
	return &runner.AnsibleConfig{
		AnsibleConfigPath: c.codePath[api.AnsibleConfigFile].Path,
		InventoryPath:     c.configPath[api.AnsibleInventoryFile].Path,

		PlaybookPathDeployKubernetes: c.codePath[api.AnsiblePlaybookDeployKubernetesFile].Path,
		PlaybookPathInfrastructure:   c.codePath[api.AnsiblePlaybookInfrustructureFiles].Path,
		PlaybookPathPrepareNodes:     c.codePath[api.AnsiblePlaybookPrepareNodesFile].Path,
		PlaybookPathJoinCluster:      c.codePath[api.AnsiblePlaybookJoinClusterFile].Path,

		KubeconfigPath: c.configPath[api.KubeconfigFile].Path,

		Env: cluster.AnsibleEnv(),
	}
}

func (c *ConfigHandler) S3CmdRunnerConfig(
	cluster api.Cluster,
) *runner.S3CmdConfig {
	return &runner.S3CmdConfig{
		CloudProviderName:         string(cluster.CloudProvider()),
		S3cfgPath:                 c.configPath[api.S3CfgFile].Path,
		ManageS3BucketsScriptPath: c.codePath[api.ManageS3BucketsScriptFile].Path,
		Buckets:                   cluster.S3Buckets(),
	}
}

func (c *ConfigHandler) KubectlRunnerConfig(
	cluster api.Cluster,
) *runner.KubectlConfig {
	return &runner.KubectlConfig{
		KubeconfigPath: c.configPath[api.KubeconfigFile].Path,
		NodePrefix:     cluster.Name(),
	}
}

func (c *ConfigHandler) SOPSRunnerConfig() *runner.SOPSConfig {
	return &runner.SOPSConfig{
		SOPSConfigPath: c.configPath[api.SOPSConfigFile].Path,
	}
}

func (c *ConfigHandler) SSHPrivateKeyPath() api.Path {
	return c.configPath[api.SSHPrivateKeyFile]
}

func (c *ConfigHandler) KubeconfigPath() api.Path {
	return c.configPath[api.KubeconfigFile]
}

func (c *ConfigHandler) configViper() *viper.Viper {
	configFilePath := c.configPath[api.ConfigFile]

	path, name, ext := splitPath(configFilePath.Path)

	v := viper.New()
	v.SetConfigName(name + "." + ext)
	v.SetConfigType(configFilePath.Format)
	v.AddConfigPath(path)

	return v
}

func (c *ConfigHandler) secretsViper() *viper.Viper {
	secretsPath := c.configPath[api.SecretsFile]

	v := viper.New()
	v.SetConfigType(secretsPath.Format)

	return v
}

func (c *ConfigHandler) readConfig() (api.Cluster, error) {
	v := c.configViper()

	if err := v.ReadInConfig(); err != nil {
		return nil, err
	}

	cloudProviderValue := v.GetString("cloud_provider")
	if cloudProviderValue == "" {
		return nil, fmt.Errorf("missing cloud provider in config")
	}

	cloudProvider, err := CloudProviderFromType(
		api.CloudProviderType(cloudProviderValue),
	)
	if err != nil {
		return nil, err
	}

	cluster := cloudProvider.Default(c.clusterType, "")

	if err := v.Unmarshal(cluster.Config()); err != nil {
		return nil, fmt.Errorf("error decoding config: %w", err)
	}

	return cluster, nil
}

func (c *ConfigHandler) readSecrets(cluster api.Cluster) error {
	secretsPath := c.configPath[api.SecretsFile]

	v := c.secretsViper()

	cleartext, err := decrypt.File(secretsPath.Path, secretsPath.Format)
	if err != nil {
		return fmt.Errorf("failed to decrypt %s: %s", secretsPath, err)
	}

	if err := v.ReadConfig(bytes.NewBuffer(cleartext)); err != nil {
		return err
	}

	if err := v.Unmarshal(cluster.Secret()); err != nil {
		return fmt.Errorf("error decoding secrets: %w", err)
	}

	return nil
}

func (c *ConfigHandler) readTFVars(cluster api.Cluster) error {
	c.logger.Debug("config_handler_tfvars_read")

	data, err := ioutil.ReadFile(c.configPath[api.TFVarsFile].Path)
	if err != nil {
		return fmt.Errorf("error reading tfvars: %w", err)
	}

	cloudProvider, err := CloudProviderFromType(cluster.CloudProvider())
	if err != nil {
		return err
	}

	if err := api.DecodeTFVars(cloudProvider, data, cluster); err != nil {
		return fmt.Errorf("error decoding tfvars: %w", err)
	}

	return nil
}

func (c *ConfigHandler) writeTFVars(cluster api.Cluster) error {
	c.logger.Debug("config_handler_tfvars_write")

	data, err := json.MarshalIndent(cluster.TFVars(), "", "  ")
	if err != nil {
		return fmt.Errorf("error encoding tfvars: %w", err)
	}

	if err := ioutil.WriteFile(
		c.configPath[api.TFVarsFile].Path,
		data,
		0644,
	); err != nil {
		return fmt.Errorf("error writing tfvars: %w", err)
	}

	return nil
}

// WriteInfraJSON TODO Remove this when apps isn't dependent on it (maybe using terraform instead)
func (c *ConfigHandler) WriteInfraJSON(
	cluster api.Cluster,
	stateFn func() (api.ClusterState, error),
	tfOutput interface{},
) error {
	c.logger.Debug("config_handler_infra_write")

	f, err := os.OpenFile(
		c.configPath[api.InfraJsonFile].Path,
		os.O_RDONLY|os.O_CREATE,
		0644,
	)
	if err != nil {
		return fmt.Errorf("error opening file: %w", err)
	}

	if err := renderInfraJSON(c, f, tfOutput); err != nil {
		return fmt.Errorf("error rendering infra inventory: %w", err)
	}

	return nil
}
