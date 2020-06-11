package main

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "get NODE_TYPE NAME",
		Short: "Get machine details",
		Args:  cobra.ExactArgs(2),
		RunE:  withClusterClient(machineGet),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "list",
		Short: "List machines",
		Args:  cobra.NoArgs,
		RunE:  withClusterClient(machineList),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "ssh NODE_TYPE NAME",
		Short: "Open an SSH login shell on a machine",
		Args:  cobra.ExactArgs(2),
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
	machines, err := clusterClient.Machines()
	if err != nil {
		return fmt.Errorf("error listing machines: %s", err)
	}

	for _, machine := range machines {
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
