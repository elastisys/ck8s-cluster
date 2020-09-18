package main

import (
	"github.com/elastisys/ck8s/client"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

const (
	destroyRemoteWorkspaceFlag = "destroy-remote-workspace"
	kubernetesCleanupFlag      = "kubernetes-cleanup"
)

func destroy(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.Destroy(viper.GetBool(destroyRemoteWorkspaceFlag), viper.GetBool(kubernetesCleanupFlag))
}

func init() {
	destroyCmd := &cobra.Command{
		Use:   "destroy",
		Short: "Destroy the CK8S cluster",
		Long:  `The destroy command tears down the CK8S cluster by destroying all Terraform managed cloud resources and all S3 buckets.`,
		Args:  NoArgs,
		RunE:  withClusterClient(destroy),
	}

	destroyCmd.Flags().Bool(
		destroyRemoteWorkspaceFlag,
		false,
		"destroy the remote Terraform workspace (CAUTION: removing it before all resources have been destroyed will make them unmanaged)",
	)
	viper.BindPFlag(
		destroyRemoteWorkspaceFlag,
		destroyCmd.Flags().Lookup(destroyRemoteWorkspaceFlag),
	)

	destroyCmd.Flags().Bool(
		kubernetesCleanupFlag,
		true,
		"tries to release volumes and loadbalancers before tearing down the cluster.",
	)
	viper.BindPFlag(
		kubernetesCleanupFlag,
		destroyCmd.Flags().Lookup(kubernetesCleanupFlag),
	)

	rootCmd.AddCommand(destroyCmd)
}
