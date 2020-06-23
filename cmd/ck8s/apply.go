package main

import (
	"github.com/elastisys/ck8s/client"
	"github.com/spf13/cobra"
)

func apply(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.Apply()
}

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "apply",
		Short: "Apply the CK8S configuration",
		Long: `The apply command creates the S3 buckets if they doesn't already exist, runs
terraform apply to create any changes in the Terraform configuration and
kubeadm init and kubeadm join to setup any new Kubernetes nodes.`,
		Args: NoArgs,
		RunE: withClusterClient(apply),
	})
}
