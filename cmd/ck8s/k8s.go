package main

import (
	"fmt"

	"github.com/spf13/cobra"

	"github.com/elastisys/ck8s/client"
)

func init() {
	rootCmd.AddCommand(&cobra.Command{
		Use:   "clone NODE_TYPE NODE_NAME",
		Short: "Clone a Kubernetes node",
		Long: `This command will clone a Kubernetes node by:
1. Cloning the machine in the tfvars configuration and running terraform
   apply.
2. Joining the new node to the Kubernetes cluster.`,
		Args: cobra.ExactArgs(2),
		RunE: withClusterClient(cloneNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "drain NODE_NAME",
		Short: "Drain a Kubernetes node",
		Long:  `This command will cordon and drain a Kubernetes node.`,
		Args:  cobra.ExactArgs(1),
		RunE:  withClusterClient(drainNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "reset NODE_TYPE NODE_NAME",
		Short: "Runs kubeadm reset on a machine",
		Long:  `This command will remove any trace of Kubernetes from a machine.`,
		Args:  cobra.ExactArgs(2),
		RunE:  withClusterClient(resetNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "remove NODE_TYPE NODE_NAME",
		Short: "Remove a Kubernetes node",
		Long: `This command will remove a node from the Kubernetes cluster and destroy the
machine by:
1. Draining the node.
2. Running kubeadm reset on old machine.
3. Removing the old machine from the Terraform configuration and running
   terraform apply.`,
		Args: cobra.ExactArgs(2),
		RunE: withClusterClient(removeNode),
	})

	rootCmd.AddCommand(&cobra.Command{
		Use:   "replace NODE_TYPE NODE_NAME",
		Short: "Replace a Kubernetes node",
		Long: `This command replaces a Kubernetes cluster node by:
1. Cloning the machine in the tfvars configuration and running terraform
   apply.
2. Joining the new node to the Kubernetes cluster.
3. Draining the old node.
3. Running kubeadm reset on old machine.
4. Removing the old machine from the Terraform configuration and running
   terraform apply.

This useful when, for example, the Kubernetes cluster needs to be updated
gracefully by performing a rolling upgrade.`,
		Args: cobra.ExactArgs(2),
		RunE: withClusterClient(replaceNode),
	})
}

func resetNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	if err := clusterClient.ResetNode(nodeType, name); err != nil {
		return fmt.Errorf("error draining node: %s", err)
	}
	return nil
}

func cloneNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	if err := clusterClient.CloneNode(nodeType, name); err != nil {
		return fmt.Errorf("error cloning node: %s", err)
	}
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
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	if err := clusterClient.ReplaceNode(nodeType, name); err != nil {
		return fmt.Errorf("error replacing node: %s", err)
	}
	return nil
}

func removeNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	nodeType, err := parseNodeTypeFlag(args[0])
	if err != nil {
		return err
	}

	name := args[1]

	if err := clusterClient.RemoveNode(nodeType, name); err != nil {
		return fmt.Errorf("error removing node: %s", err)
	}
	return nil
}
