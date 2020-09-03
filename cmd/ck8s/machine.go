package main

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "get NAME",
		Short: "Get machine details",
		Args:  ExactArgs(1),
		RunE:  withClusterClient(machineGet),
	})

	listCmd := &cobra.Command{
		Use:   "list",
		Short: "List machines",
		Args:  NoArgs,
		RunE:  withClusterClient(machineList),
	}
	listCmd.Flags().String(
		nodeTypeFlag,
		"",
		"filter by node type",
	)
	viper.BindPFlag(
		nodeTypeFlag,
		listCmd.Flags().Lookup(nodeTypeFlag),
	)
	rootCmd.AddCommand(listCmd)

	rootCmd.AddCommand(&cobra.Command{
		Use:   "images NODE_TYPE",
		Short: "List available machine images",
		Args:  ExactArgs(1),
		RunE:  withClusterClient(machineImages),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "ssh NAME",
		Short: "Open an SSH login shell on a machine",
		Args:  ExactArgs(1),
		RunE:  withClusterClient(machineSSH),
	})
}

func printMachine(name string, machine api.MachineState) {
	fmt.Println(
		machine.NodeType,
		name,
		machine.PublicIP,
		machine.PrivateIP,
	)
}

func machineGet(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	machine, err := clusterClient.Machine(name)
	if err != nil {
		return fmt.Errorf("error getting machine: %s", err)
	}

	printMachine(name, machine)

	return nil
}

func machineList(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType := api.NodeType(viper.GetString(nodeTypeFlag))

	machines, err := clusterClient.Machines()
	if err != nil {
		return fmt.Errorf("error listing machines: %s", err)
	}

	for name, machine := range machines {
		if nodeType != "" && machine.NodeType != nodeType {
			continue
		}

		printMachine(name, machine)
	}

	return nil
}

func machineImages(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType := api.NodeType(args[0])

	images, err := clusterClient.MachineImages(nodeType)
	if err != nil {
		return fmt.Errorf("error getting machine images: %s", err)
	}

	for _, image := range images {
		fmt.Println(image.Name)
	}

	return nil
}

func machineSSH(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	machine, err := clusterClient.Machine(name)
	if err != nil {
		return fmt.Errorf("error getting machine: %w", err)
	}

	return clusterClient.MachineClient(machine).Shell()
}
