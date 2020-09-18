package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

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
	logger *zap.Logger
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
		return -1, fmt.Errorf("cluster flag cannot be empty")
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

func setupLogger() error {
	if logger != nil {
		panic("logger already setup")
	}

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

	return nil
}

func newConfigHandler(
	clusterType api.ClusterType,
) (*client.ConfigHandler, error) {
	configRootPath := viper.GetString(configPathFlag)
	if configRootPath == "" {
		return nil, fmt.Errorf("config path cannot be empty")
	}

	codeRootPath, err := filepath.Abs(viper.GetString(codePathFlag))
	if err != nil {
		return nil, err
	}

	configPath := api.NewConfigPath(configRootPath, clusterType)

	codePath := api.NewCodePath(codeRootPath, clusterType)

	return client.NewConfigHandler(
		logger,
		clusterType,
		configPath,
		codePath,
	), nil
}

func newClusterClient(
	configHandler *client.ConfigHandler,
) (*client.ClusterClient, error) {
	cluster, err := configHandler.Read()
	if err != nil {
		return nil, fmt.Errorf("error reading config path: %w", err)
	}

	silent := viper.GetBool(silentFlag)

	localRunner := runner.NewLocalRunner(logger, silent)

	return client.NewClusterClient(
		logger,
		cluster,
		configHandler,
		localRunner,
		silent,
		viper.GetBool(autoApproveFlag),
	)
}

func withClusterClient(fn func(
	*client.ClusterClient,
	*cobra.Command,
	[]string,
) error) func(*cobra.Command, []string) error {
	return func(cmd *cobra.Command, args []string) error {
		clusterType, err := parseClusterFlag()
		if err != nil {
			return err
		}

		configHandler, err := newConfigHandler(clusterType)
		if err != nil {
			return err
		}

		clusterClient, err := newClusterClient(configHandler)
		if err != nil {
			return err
		}

		return fn(clusterClient, cmd, args)
	}
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
