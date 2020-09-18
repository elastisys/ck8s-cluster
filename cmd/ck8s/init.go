package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

const (
	clusterFlavorFlag    = "flavor"
	defaultClusterFlavor = "dev"

	pgpFingerprintFlag = "pgp-fp"
)

func init() {
	initCmd := &cobra.Command{
		Use:   "init CLUSTER_NAME CLOUD_PROVIDER",
		Short: "Initialize the CK8S configuration and Terraform workspace",
		Args:  ExactArgs(2),
		RunE: func(cmd *cobra.Command, args []string) error {
			if _, ok := os.LookupEnv("CK8S_PGP_UID"); ok {
				return fmt.Errorf(
					"CK8S_PGP_UID is currently not supported, use CK8S_PGP_FP or the --pgp-fp flag instead",
				)
			}

			// TODO: Remove after deprecation period is over
			if _, ok := os.LookupEnv("CK8S_ENVIRONMENT_NAME"); ok {
				return fmt.Errorf(
					"CK8S_ENVIRONMENT_NAME is deprecated, use positional arg",
				)
			}
			if _, ok := os.LookupEnv("CK8S_CLOUD_PROVIDER"); ok {
				return fmt.Errorf(
					"CK8S_CLOUD_PROVIDER is deprecated, use positional arg",
				)
			}

			clusterName := args[0]

			cloudProvider, err := client.CloudProviderFromType(
				api.CloudProviderType(args[1]),
			)
			if err != nil {
				return err
			}

			clusterFlavor := api.ClusterFlavor(
				viper.GetString(clusterFlavorFlag),
			)

			pgpFP := viper.GetString(pgpFingerprintFlag)
			if pgpFP == "" {
				return fmt.Errorf("PGP fingerprint cannot be empty")
			}

			for _, clusterType := range []api.ClusterType{
				api.ServiceCluster,
				api.WorkloadCluster,
			} {
				cluster, err := cloudProvider.Cluster(
					clusterType,
					clusterFlavor,
					clusterName,
				)
				if err != nil {
					return err
				}

				configHandler, err := newConfigHandler(clusterType)
				if err != nil {
					return err
				}

				configInitializer := client.NewConfigInitializer(
					logger,
					cloudProvider,
					configHandler,
				)

				if err := configInitializer.Init(cluster, pgpFP); err != nil {
					return err
				}
			}

			return nil
		},
	}

	initCmd.Flags().String(
		clusterFlavorFlag,
		defaultClusterFlavor,
		"cluster flavor",
	)
	viper.BindPFlag(
		clusterFlavorFlag,
		initCmd.Flags().Lookup(clusterFlavorFlag),
	)

	initCmd.Flags().String(
		pgpFingerprintFlag,
		"",
		"PGP fingerprint",
	)
	viper.BindPFlag(
		pgpFingerprintFlag,
		initCmd.Flags().Lookup(pgpFingerprintFlag),
	)

	rootCmd.AddCommand(initCmd)
}
