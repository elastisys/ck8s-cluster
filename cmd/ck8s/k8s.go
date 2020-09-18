package main

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

const (
	nameFlag                   = "name"
	imageFlag                  = "image"
	esLocalStorageCapacityFlag = "es-local-storage"
)

func init() {
	addCmd := &cobra.Command{
		Use:   "add NODE_TYPE SIZE",
		Short: "Add a Kubernetes node",
		Long: `This command will add a Kubernetes node by:
1. Adding the machine in the tfvars.json configuration and running terraform apply.
2. Joining the new node to the Kubernetes cluster.`,
		Args: ExactArgs(2),
		PreRun: func(cmd *cobra.Command, args []string) {
			viper.BindPFlag(nameFlag, cmd.Flags().Lookup(nameFlag))
			viper.BindPFlag(imageFlag, cmd.Flags().Lookup(imageFlag))
			viper.BindPFlag(
				esLocalStorageCapacityFlag,
				cmd.Flags().Lookup(esLocalStorageCapacityFlag),
			)
		},
		RunE: withClusterClient(addNode),
	}
	addCmd.Flags().String(nameFlag, "", "set name")
	addCmd.Flags().String(imageFlag, "", "set image")
	addCmd.Flags().Float64(
		esLocalStorageCapacityFlag,
		0,
		"set reserved local storage for Elasticsearch (Exoscale only)",
	)
	rootCmd.AddCommand(addCmd)

	cloneCmd := &cobra.Command{
		Use:   "clone NODE_NAME",
		Short: "Clone a Kubernetes node",
		Long: `This command will clone a Kubernetes node by:
1. Cloning the machine in the tfvars.json configuration and running terraform apply. Optionally with a different image.
2. Joining the new node to the Kubernetes cluster.`,
		Args: ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			viper.BindPFlag(imageFlag, cmd.Flags().Lookup(imageFlag))
		},
		RunE: withClusterClient(cloneNode),
	}
	cloneCmd.Flags().String(imageFlag, "", "set image")
	rootCmd.AddCommand(cloneCmd)

	rootCmd.AddCommand(&cobra.Command{
		Use:   "drain NODE_NAME",
		Short: "Drain a Kubernetes node",
		Long:  `This command will cordon and drain a Kubernetes node.`,
		Args:  ExactArgs(1),
		RunE:  withClusterClient(drainNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "reset NODE_NAME",
		Short: "Runs kubeadm reset on a machine",
		Long:  `This command will remove any trace of Kubernetes from a machine.`,
		Args:  ExactArgs(1),
		RunE:  withClusterClient(resetNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "remove NODE_NAME",
		Short: "Remove a Kubernetes node",
		Long: `This command will remove a node from the Kubernetes cluster and destroy the
machine by:
1. Draining the node.
2. Running kubeadm reset on old machine.
3. Removing the old machine from the Terraform configuration and running terraform apply.`,
		Args: ExactArgs(1),
		RunE: withClusterClient(removeNode),
	})

	replaceCmd := &cobra.Command{
		Use:   "replace NODE_NAME",
		Short: "Replace a Kubernetes node",
		Long: `This command replaces a Kubernetes cluster node by:
1. Cloning the machine in the tfvars.json configuration and running terraform apply. Optionally with a different image.
2. Joining the new node to the Kubernetes cluster.
3. Draining the old node.
3. Running kubeadm reset on old machine.
4. Removing the old machine from the Terraform configuration and running terraform apply.

This useful when, for example, the Kubernetes cluster needs to be updated gracefully by performing a rolling upgrade.`,
		Args: ExactArgs(1),
		PreRun: func(cmd *cobra.Command, args []string) {
			viper.BindPFlag(imageFlag, cmd.Flags().Lookup(imageFlag))
		},
		RunE: withClusterClient(replaceNode),
	}
	replaceCmd.Flags().String(imageFlag, "", "set image")
	rootCmd.AddCommand(replaceCmd)
}

func addNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var providerSettings map[string]interface{}

	if viper.IsSet(esLocalStorageCapacityFlag) {
		providerSettings = map[string]interface{}{
			"es_local_storage_capacity": viper.GetFloat64(
				esLocalStorageCapacityFlag,
			),
		}
	}

	name, err := clusterClient.AddMachine(
		viper.GetString(nameFlag),
		api.NodeType(args[0]),
		args[1],
		viper.GetString(imageFlag),
		providerSettings,
	)
	if err != nil {
		return fmt.Errorf("error adding machine to configuration: %s", err)
	}

	machineState, err := clusterClient.Join(name)
	if err != nil {
		return fmt.Errorf("error joining node: %s", err)
	}

	printMachine(name, machineState)

	return nil
}

func resetNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	if err := clusterClient.ResetNode(name); err != nil {
		return fmt.Errorf("error resetting node: %s", err)
	}
	return nil
}

func cloneNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	cloneName, err := clusterClient.CloneMachine(
		name,
		viper.GetString(imageFlag),
	)
	if err != nil {
		return fmt.Errorf("error cloning machine in configuration: %s", err)
	}

	machineState, err := clusterClient.Join(cloneName)
	if err != nil {
		return fmt.Errorf("error joining node: %s", err)
	}

	printMachine(cloneName, machineState)

	return nil
}

func drainNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	if err := clusterClient.DrainNode(name); err != nil {
		return fmt.Errorf("error draining node: %s", err)
	}
	return nil
}

func replaceNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	cloneName, err := clusterClient.CloneMachine(
		name,
		viper.GetString(imageFlag),
	)
	if err != nil {
		return fmt.Errorf("error cloning machine in configuration: %s", err)
	}

	machineState, err := clusterClient.Join(cloneName)
	if err != nil {
		return fmt.Errorf("error joining node: %s", err)
	}

	if err := clusterClient.RemoveNode(name); err != nil {
		return fmt.Errorf("error removing node: %s", err)
	}

	printMachine(cloneName, machineState)

	return nil
}

func removeNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	name := args[0]

	if err := clusterClient.RemoveNode(name); err != nil {
		return fmt.Errorf("error removing node: %s", err)
	}
	return nil
}
