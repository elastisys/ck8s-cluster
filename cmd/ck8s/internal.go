package main

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/elastisys/ck8s/client"
)

func terraformApply(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.TerraformApply()
}

func terraformOutput(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var output interface{}
	if err := clusterClient.TerraformOutput(&output); err != nil {
		return err
	}
	outputJson, err := json.Marshal(&output)
	if err != nil {
		return err
	}
	fmt.Println(string(outputJson))
	return nil
}

func terraformDestroy(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.TerraformDestroy()
}

func kubectl(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	return clusterClient.Kubectl(args)
}

func init() {
	internal := &cobra.Command{
		Use:   "internal",
		Short: "Only use if you know what you're doing.",
		Args:  NoArgs,
	}

	tf := &cobra.Command{
		Use:   "terraform",
		Short: "Direct access to Terraform commands",
		Args:  NoArgs,
	}

	tf.AddCommand(&cobra.Command{
		Use:   "apply",
		Short: "Apply the Terraform configuration",
		Args:  NoArgs,
		RunE:  withClusterClient(terraformApply),
	})

	tf.AddCommand(&cobra.Command{
		Use:   "output",
		Short: "Get the raw Terraform output in JSON format",
		Args:  NoArgs,
		RunE:  withClusterClient(terraformOutput),
	})

	tf.AddCommand(&cobra.Command{
		Use:   "destroy",
		Short: "Destroy the Terraform managed infrastructure",
		Args:  cobra.NoArgs,
		RunE:  withClusterClient(terraformDestroy),
	})

	internal.AddCommand(tf)

	internal.AddCommand(&cobra.Command{
		Use:   "kubectl",
		Short: "Direct kubectl access",
		Args:  cobra.ArbitraryArgs,
		RunE:  withClusterClient(kubectl),
	})

	rootCmd.AddCommand(internal)
}
