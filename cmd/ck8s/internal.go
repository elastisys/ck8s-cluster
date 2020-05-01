package main

import (
	"encoding/json"
	"fmt"

	"github.com/spf13/cobra"
)

func terraformApply(cmd *cobra.Command, args []string) error {
	return clusterClient.TerraformApply()
}

func terraformOutput(cmd *cobra.Command, args []string) error {
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

func init() {
	internal := &cobra.Command{
		Use:   "internal",
		Short: "Only use if you know what you're doing.",
		Args:  cobra.NoArgs,
	}

	tf := &cobra.Command{
		Use:   "terraform",
		Short: "Direct access to Terraform commands",
		Args:  cobra.NoArgs,
	}

	tf.AddCommand(&cobra.Command{
		Use:   "apply",
		Short: "Apply the Terraform configuration",
		Args:  cobra.NoArgs,
		RunE:  terraformApply,
	})

	tf.AddCommand(&cobra.Command{
		Use:   "output",
		Short: "Get the raw Terraform output in JSON format",
		Args:  cobra.NoArgs,
		RunE:  terraformOutput,
	})

	internal.AddCommand(tf)

	rootCmd.AddCommand(internal)
}
