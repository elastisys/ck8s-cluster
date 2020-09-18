package client

import (
	"bytes"
	"fmt"
	"io/ioutil"

	"go.uber.org/zap"
	"gopkg.in/yaml.v2"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

type ConfigInitializer struct {
	cloudProvider api.CloudProvider
	configHandler *ConfigHandler

	sops *runner.SOPS

	logger *zap.Logger
}

func NewConfigInitializer(
	logger *zap.Logger,
	cloudProvider api.CloudProvider,
	configHandler *ConfigHandler,
) *ConfigInitializer {
	return &ConfigInitializer{
		cloudProvider: cloudProvider,
		configHandler: configHandler,

		sops: runner.NewSOPS(
			logger,
			runner.NewLocalRunner(logger, true),
			configHandler.SOPSRunnerConfig(),
		),

		logger: logger.With(
			zap.String("cluster", configHandler.clusterType.String()),
		),
	}
}

// Init validates and writes an initial cluster configuration to the config
// path.
func (c *ConfigInitializer) Init(
	cluster api.Cluster,
	pgpFingerprint string,
) error {
	if err := api.ValidateCluster(cluster); err != nil {
		return fmt.Errorf("config validation failed: %w", err)
	}

	if err := c.initSOPSConfig(pgpFingerprint); err != nil {
		return fmt.Errorf("error initializing SOPS config: %w", err)
	}

	if err := c.initSSHKeyPair(); err != nil {
		return fmt.Errorf("error initializing SSH key pair: %w", err)
	}

	if err := c.initTerraformBackendConfig(); err != nil {
		return fmt.Errorf("error initializing backend config: %w", err)
	}

	if err := c.initConfig(cluster); err != nil {
		return fmt.Errorf("error initializing config: %w", err)
	}

	if err := c.initSecrets(cluster); err != nil {
		return fmt.Errorf("error initializing secrets: %w", err)
	}

	if err := c.initTFVars(cluster); err != nil {
		return fmt.Errorf("error initializing tfvars: %w", err)
	}

	return nil
}

func (c *ConfigInitializer) initSOPSConfig(pgpFingerprint string) error {
	c.logger.Info("config_init_sops_config")

	sopsConfigPath := c.configHandler.configPath[api.SOPSConfigFile]

	if exists, err := mkdirAllIfNotExists(sopsConfigPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_sops_config_already_exists")
		return nil
	}

	sopsConfig := NewSOPSConfig(pgpFingerprint)

	sopsConfigYAML, err := yaml.Marshal(sopsConfig)
	if err != nil {
		return fmt.Errorf("error encoding SOPS config to YAML: %w", err)
	}

	return ioutil.WriteFile(
		sopsConfigPath.Path,
		sopsConfigYAML,
		0644,
	)
}

func (c *ConfigInitializer) initSSHKeyPair() error {
	c.logger.Info("config_init_ssh_key_pair")

	var pubKey, privKeyPlain, privKeyEnc bytes.Buffer

	sshPrivKeyPath := c.configHandler.configPath[api.SSHPrivateKeyFile]
	sshPubKeyPath := c.configHandler.configPath[api.SSHPublicKeyFile]

	if exists, err := mkdirAllIfNotExists(sshPrivKeyPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_ssh_private_key_already_exists")
		return nil
	}
	if exists, err := mkdirAllIfNotExists(sshPubKeyPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_ssh_public_key_already_exists")
		return nil
	}

	if err := generateSSHKeyPair(&pubKey, &privKeyPlain); err != nil {
		return fmt.Errorf("failed to generate SSH key pair: %w", err)
	}

	if err := c.sops.EncryptStdin(
		"bytes",
		"bytes",
		&privKeyPlain,
		&privKeyEnc,
	); err != nil {
		return fmt.Errorf("error encrypting private SSH key: %w", err)
	}

	if err := ioutil.WriteFile(
		sshPrivKeyPath.Path,
		privKeyEnc.Bytes(),
		0400,
	); err != nil {
		return fmt.Errorf("error writing private SSH key: %w", err)
	}

	if err := ioutil.WriteFile(
		sshPubKeyPath.Path,
		pubKey.Bytes(),
		0644,
	); err != nil {
		return fmt.Errorf("error writing public SSH key: %w", err)
	}

	return nil
}

func (c *ConfigInitializer) initTerraformBackendConfig() error {
	c.logger.Info("config_init_terraform_backend_config")

	backendConfigPath := c.configHandler.configPath[api.TFBackendConfigFile]

	if exists, err := mkdirAllIfNotExists(backendConfigPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_terraform_backend_config_already_exists")
		return nil
	}

	backendConfig := c.cloudProvider.TerraformBackendConfig()

	return ioutil.WriteFile(
		backendConfigPath.Path,
		hclEncode(backendConfig),
		0644,
	)
}

func (c *ConfigInitializer) initConfig(cluster api.Cluster) error {
	c.logger.Info("config_init_config")

	configPath := c.configHandler.configPath[api.ConfigFile]

	if exists, err := mkdirAllIfNotExists(configPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_config_already_exists")
		return nil
	}

	config, err := yaml.Marshal(cluster.Config())
	if err != nil {
		return fmt.Errorf("error marshalling config: %w", err)
	}

	return ioutil.WriteFile(
		configPath.Path,
		config,
		0644,
	)
}

func (c *ConfigInitializer) initSecrets(cluster api.Cluster) error {
	c.logger.Info("config_init_secrets")

	secretsPath := c.configHandler.configPath[api.SecretsFile]

	if exists, err := mkdirAllIfNotExists(secretsPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_secrets_already_exists")
		return nil
	}

	config, err := yaml.Marshal(cluster.Secret())
	if err != nil {
		return fmt.Errorf("error marshalling config: %w", err)
	}

	var encryptedLines bytes.Buffer
	plaintextLines := bytes.NewBuffer(config)

	if err := c.sops.EncryptStdin(
		secretsPath.Format,
		secretsPath.Format,
		plaintextLines,
		&encryptedLines,
	); err != nil {
		return fmt.Errorf("error encrypting secrets: %w", err)
	}

	return ioutil.WriteFile(
		secretsPath.Path,
		encryptedLines.Bytes(),
		0644,
	)
}

func (c *ConfigInitializer) initTFVars(cluster api.Cluster) error {
	c.logger.Info("config_init_tfvars")

	tfvarsPath := c.configHandler.configPath[api.TFVarsFile]

	if exists, err := mkdirAllIfNotExists(tfvarsPath); err != nil {
		return err
	} else if exists {
		c.logger.Debug("config_init_tfvars_already_exists")
		return nil
	}

	if err := c.configHandler.writeTFVars(cluster); err != nil {
		return fmt.Errorf("error writing tfvars: %w", err)
	}

	return nil
}
