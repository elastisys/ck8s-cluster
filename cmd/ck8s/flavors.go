package main

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

func flavors(cmd *cobra.Command, args []string) error {
	cloudProvider, err := client.CloudProviderFromType(
		api.CloudProviderType(args[0]),
	)
	if err != nil {
		return err
	}

	for _, flavor := range cloudProvider.Flavors() {
		fmt.Println(flavor)
	}

	return nil
}

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "flavors CLOUD_PROVIDER",
		Short: "List the available cluster flavors",
		Args:  ExactArgs(1),
		RunE:  flavors,
	})
}
