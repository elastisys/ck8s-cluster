package main

import (
	"github.com/elastisys/ck8s/client"
	"github.com/spf13/cobra"
)

func destroy(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.Destroy()
}

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "destroy",
		Short: "Destroy the CK8S cluster",
		Long: `The destroy command tears down the CK8S cluster by destroying
all Terraform managed cloud resources and all S3 buckets.`,
		Args: cobra.NoArgs,
		RunE: withClusterClient(destroy),
	})
}
