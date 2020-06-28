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
		Use:   "get NODE_TYPE NAME",
		Short: "Get machine details",
		Args:  ExactArgs(2),
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
		Use:   "ssh NODE_TYPE NAME",
		Short: "Open an SSH login shell on a machine",
		Args:  ExactArgs(2),
		RunE:  withClusterClient(machineSSH),
	})
}

func printMachine(machine api.MachineState) {
	fmt.Println(
		machine.NodeType,
		machine.Name,
		machine.PublicIP,
		machine.PrivateIP,
	)
}

func machineGet(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	machine, err := clusterClient.Machine(nodeType, name)
	if err != nil {
		return fmt.Errorf("error getting machine: %s", err)
	}

	printMachine(machine)

	return nil
}

func machineList(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var nodeType api.NodeType

	nodeTypeStr := viper.GetString(nodeTypeFlag)
	if nodeTypeStr != "" {
		var err error
		if nodeType, err = parseNodeTypeFlag(nodeTypeStr); err != nil {
			return err
		}
	}

	machines, err := clusterClient.Machines()
	if err != nil {
		return fmt.Errorf("error listing machines: %s", err)
	}

	for _, machine := range machines {
		if nodeType != 0 && machine.NodeType != nodeType {
			continue
		}

		printMachine(machine)
	}

	return nil
}

func machineSSH(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	machine, err := clusterClient.Machine(nodeType, name)
	if err != nil {
		return fmt.Errorf("error getting machine: %w", err)
	}

	return clusterClient.MachineClient(machine).Shell()
}
