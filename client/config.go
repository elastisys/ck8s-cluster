package client

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"

	"github.com/spf13/viper"
	"go.mozilla.org/sops/v3/decrypt"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

type ConfigHandler struct {
	clusterType api.ClusterType
	configPath  api.ConfigPath
	codePath    api.CodePath
}

func NewConfigHandler(
	clusterType api.ClusterType,
	configPath api.ConfigPath,
	codePath api.CodePath,
) *ConfigHandler {
	return &ConfigHandler{
		clusterType: clusterType,
		configPath:  configPath,
		codePath:    codePath,
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

// Save validates and saves a cluster configuration to the config path.
func (c *ConfigHandler) Write(cluster api.Cluster) error {
	if err := api.ValidateCluster(cluster); err != nil {
		return fmt.Errorf("config validation failed: %w", err)
	}

	if err := c.writeConfig(cluster); err != nil {
		return fmt.Errorf("error saving config: %w", err)
	}

	if err := c.writeSecrets(cluster); err != nil {
		return fmt.Errorf("error saving secrets: %w", err)
	}

	if err := c.writeTFVars(cluster); err != nil {
		return fmt.Errorf("error saving tfvars: %w", err)
	}

	return nil
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
	var s3cfgPlain, s3cfgEnc bytes.Buffer

	path := c.configPath[api.S3CfgFile]

	if err := renderS3CfgPlaintext(cluster, &s3cfgPlain); err != nil {
		return fmt.Errorf("error rendering plaintext s3cfg: %w", err)
	}

	if err := encryptFn(path.Format, &s3cfgPlain, &s3cfgEnc); err != nil {
		return fmt.Errorf("error encrypting s3cfg: %w", err)
	}

	if err := ioutil.WriteFile(
		path.Path,
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

func (c *ConfigHandler) TerraformConfig(
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
	default:
		return nil, api.NewUnsupportedCloudProviderError(cloudProvider)
	}
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

func (c *ConfigHandler) AnsibleConfig(cluster api.Cluster) *runner.AnsibleConfig {
	ansibleEnv := cluster.AnsibleEnv()
	return &runner.AnsibleConfig{
		AnsibleConfigPath: c.codePath[api.AnsibleConfigFile].Path,
		InventoryPath:     c.configPath[api.AnsibleInventoryFile].Path,

		PlaybookPathDeployKubernetes: c.codePath[api.AnsiblePlaybookDeployKubernetesFile].Path,
		PlaybookPathInfrastructure:   c.codePath[api.AnsiblePlaybookInfrustructureFiles].Path,
		PlaybookPathPrepareNodes:     c.codePath[api.AnsiblePlaybookPrepareNodesFile].Path,
		PlaybookPathJoinCluster:      c.codePath[api.AnsiblePlaybookJoinClusterFile].Path,

		KubeconfigPath: c.configPath[api.KubeconfigFile].Path,
		CRDFilePath:    c.codePath[api.CRDFile].Path,

		Env: ansibleEnv,
	}
}

func (c *ConfigHandler) S3CmdConfig(cluster api.Cluster) *runner.S3CmdConfig {
	return &runner.S3CmdConfig{
		CloudProviderName:         string(cluster.CloudProvider()),
		S3cfgPath:                 c.configPath[api.S3CfgFile].Path,
		ManageS3BucketsScriptPath: c.codePath[api.ManageS3BucketsScriptFile].Path,
		Buckets:                   cluster.S3Buckets(),
	}
}

func (c *ConfigHandler) KubectlConfig(
	cluster api.Cluster,
) *runner.KubectlConfig {
	return &runner.KubectlConfig{
		KubeconfigPath: c.configPath[api.KubeconfigFile].Path,
		NodePrefix:     cluster.Name(),
	}
}

func (c *ConfigHandler) SOPSConfig() *runner.SOPSConfig {
	return &runner.SOPSConfig{
		SOPSConfigPath: c.configPath[api.SOPSConfigFile].Path,
	}
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
	tfvarsPath := c.configPath[api.TFVarsFile]

	tfvarsData, err := ioutil.ReadFile(tfvarsPath.Path)
	if err != nil {
		return fmt.Errorf("error reading tfvars: %w", err)
	}

	if err := tfvarsDecode(tfvarsData, cluster.TFVars()); err != nil {
		return fmt.Errorf("error decoding tfvars: %w", err)
	}

	return nil
}

func (c *ConfigHandler) writeConfig(cluster api.Cluster) error {
	v := c.configViper()

	v.SetConfigPermissions(0644)

	if err := v.Unmarshal(cluster.Config()); err != nil {
		return fmt.Errorf("error unmarshaling config: %w", err)
	}

	if err := v.WriteConfig(); err != nil {
		return fmt.Errorf("error writing config: %w", err)
	}

	return nil
}

func (c *ConfigHandler) writeSecrets(cluster api.Cluster) error {
	v := c.secretsViper()

	v.SetConfigPermissions(0644)

	if err := v.Unmarshal(cluster.Secret()); err != nil {
		return fmt.Errorf("error unmarshaling config: %w", err)
	}

	if err := v.WriteConfig(); err != nil {
		return fmt.Errorf("error writing config: %w", err)
	}

	return nil
}

func (c *ConfigHandler) writeTFVars(cluster api.Cluster) error {
	return ioutil.WriteFile(
		c.configPath[api.TFVarsFile].Path,
		tfvarsEncode(cluster.TFVars()),
		0644,
	)
}
