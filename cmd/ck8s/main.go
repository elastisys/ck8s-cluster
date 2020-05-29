package main

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
	"github.com/elastisys/ck8s/runner"
)

var version = "dev"

var (
	configPathFlag  = "config-path"
	codePathFlag    = "code-path"
	clusterFlag     = "cluster"
	nodeTypeFlag    = "node-type"
	logLevelFlag    = "log-level"
	silentFlag      = "silent"
	autoApproveFlag = "auto-approve"
)

var (
	clusterClient *client.ClusterClient
	logger        *zap.Logger
)

var rootCmd = &cobra.Command{
	Use:               "ck8s",
	Short:             "Elastisys Compliant Kubernetes",
	PersistentPreRunE: setup,
	SilenceUsage:      true,
}

func init() {
	rootCmd.Version = version

	viper.SetEnvPrefix("CK8S")
	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))
	viper.AutomaticEnv()

	rootCmd.PersistentFlags().String(
		configPathFlag,
		"",
		"path to CK8S config directory",
	)
	viper.BindPFlag(
		configPathFlag,
		rootCmd.PersistentFlags().Lookup(configPathFlag),
	)

	rootCmd.PersistentFlags().String(
		codePathFlag,
		".",
		"path to CK8S code base",
	)
	viper.BindPFlag(
		codePathFlag,
		rootCmd.PersistentFlags().Lookup(codePathFlag),
	)

	rootCmd.PersistentFlags().String(
		clusterFlag,
		"",
		fmt.Sprintf(
			"cluster to perform operations on, valid values (%s|%s)",
			api.ServiceCluster, api.WorkloadCluster,
		),
	)
	viper.BindPFlag(
		clusterFlag,
		rootCmd.PersistentFlags().Lookup(clusterFlag),
	)

	rootCmd.PersistentFlags().String(
		logLevelFlag,
		zap.InfoLevel.String(),
		"minimum log level",
	)
	viper.BindPFlag(
		logLevelFlag,
		rootCmd.PersistentFlags().Lookup(logLevelFlag),
	)

	rootCmd.PersistentFlags().Bool(
		silentFlag,
		false,
		"silent output (hide output from subcommands)",
	)
	viper.BindPFlag(
		silentFlag,
		rootCmd.PersistentFlags().Lookup(silentFlag),
	)

	rootCmd.PersistentFlags().Bool(
		autoApproveFlag,
		false,
		"skip interactive approval",
	)
	viper.BindPFlag(
		autoApproveFlag,
		rootCmd.PersistentFlags().Lookup(autoApproveFlag),
	)
}

func parseClusterFlag() (api.ClusterType, error) {
	cluster := viper.GetString(clusterFlag)

	if cluster == "" {
		return -1, fmt.Errorf("cluster cannot be empty")
	}

	switch cluster {
	case api.ServiceCluster.String():
		return api.ServiceCluster, nil
	case api.WorkloadCluster.String():
		return api.WorkloadCluster, nil
	default:
		return -1, fmt.Errorf("invalid cluster: %s", cluster)
	}
}

func parseNodeTypeFlag(nodeType string) (api.NodeType, error) {
	switch nodeType {
	case api.Master.String():
		return api.Master, nil
	case api.Worker.String():
		return api.Worker, nil
	default:
		return -1, fmt.Errorf("invalid node type: %s", nodeType)
	}
}

func setupClusterClient() error {
	configRootPath := viper.GetString(configPathFlag)
	if configRootPath == "" {
		return fmt.Errorf("config path cannot be empty")
	}

	clusterType, err := parseClusterFlag()
	if err != nil {
		return err
	}

	codeRootPath, err := filepath.Abs(viper.GetString(codePathFlag))
	if err != nil {
		return err
	}

	configPath := api.NewConfigPath(configRootPath, clusterType)
	codePath := api.NewCodePath(codeRootPath, clusterType)

	cluster, err := client.ClusterFromConfigPath(clusterType, configPath)
	if err != nil {
		return err
	}

	tfPath, err := api.TerraformPath(codeRootPath, cluster.CloudProvider())
	if err != nil {
		return err
	}
	if err := tfPath.Exists(); err != nil {
		var notFoundErr *api.PathNotFoundError
		if errors.As(err, &notFoundErr) {
			return fmt.Errorf(
				"terraform path not found: %s\nwrong CK8S code path?",
				notFoundErr.Path.Path,
			)
		}
		return err
	}

	// TODO: Exoscale specific
	var tfTarget string
	switch clusterType {
	case api.ServiceCluster:
		tfTarget = "module.service_cluster"
	case api.WorkloadCluster:
		tfTarget = "module.workload_cluster"
	}

	tfEnv := cluster.TerraformEnv(
		api.NewConfigPath(
			configRootPath,
			api.ServiceCluster,
		)[api.SSHPublicKeyFile].Path,
		api.NewConfigPath(
			configRootPath,
			api.WorkloadCluster,
		)[api.SSHPublicKeyFile].Path,
	)

	tfConfig := &runner.TerraformConfig{
		Path:              tfPath.Path,
		Workspace:         cluster.TerraformWorkspace(),
		DataDirPath:       configPath[api.TFDataDir].Path,
		BackendConfigPath: configPath[api.TFBackendConfigFile].Path,
		TFVarsPath:        configPath[api.TFVarsFile].Path,

		Target: tfTarget,

		Env: tfEnv,
	}

	clusterClient = client.NewClusterClient(
		logger,
		cluster,
		viper.GetBool(silentFlag),
		viper.GetBool(autoApproveFlag),
		configPath,
		codePath,
		tfConfig,
	)

	return nil
}

func setupLogger() error {
	config := zap.NewDevelopmentConfig()

	logLevel := viper.GetString(logLevelFlag)
	if logLevel != "" {
		if err := config.Level.UnmarshalText([]byte(logLevel)); err != nil {
			return err
		}
	}

	config.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	config.DisableStacktrace = true

	var err error
	logger, err = config.Build()
	if err != nil {
		return fmt.Errorf("error building logger: %s", err)
	}

	return nil
}

func setup(cmd *cobra.Command, args []string) error {
	if err := setupLogger(); err != nil {
		return fmt.Errorf("error setting up logger: %s", err)
	}

	if err := setupClusterClient(); err != nil {
		return fmt.Errorf("error setting up client: %s", err)
	}

	return nil
}

func main() {
	defer func() {
		if logger != nil {
			logger.Sync()
		}
	}()
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}
