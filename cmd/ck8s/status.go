package main

import (
	"fmt"
	"time"

	"github.com/hashicorp/go-multierror"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/client"
)

const (
	sshTimeoutFlag    = "ssh-timeout"
	sshDefaultTimeout = 10 * time.Second
)

func init() {
	statusCmd := &cobra.Command{
		Use:   "status",
		Short: "Cluster status",
		Args:  NoArgs,
		RunE:  withClusterClient(status),
	}

	statusCmd.PersistentFlags().Duration(
		sshTimeoutFlag,
		sshDefaultTimeout,
		"SSH timeout in seconds",
	)
	viper.BindPFlag(
		sshTimeoutFlag,
		statusCmd.PersistentFlags().Lookup(sshTimeoutFlag),
	)

	statusCmd.AddCommand(&cobra.Command{
		Use:   "ssh",
		Short: "Check SSH status",
		Args:  NoArgs,
		RunE:  withClusterClient(statusSSH),
	})

	statusCmd.AddCommand(&cobra.Command{
		Use:   "node",
		Short: "Check node existence in Kubernetes",
		Args:  NoArgs,
		RunE:  withClusterClient(statusNode),
	})

	rootCmd.AddCommand(statusCmd)
}

func printMachineStatus(
	statusName string,
	machineName string,
	machine *api.Machine,
	success bool,
) {
	status := Green.Fmt("✔️")
	if !success {
		status = Red.Fmt("❌")
	}
	fmt.Println(fmt.Sprintf(
		"%s %s %s %s",
		statusName,
		machine.NodeType,
		machineName,
		status,
	))
}

func status(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var errChain error

	if err := statusSSH(clusterClient, cmd, args); err != nil {
		errChain = multierror.Append(errChain, err)
	}

	if err := statusNode(clusterClient, cmd, args); err != nil {
		errChain = multierror.Append(errChain, err)
	}

	return errChain
}

func statusSSH(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var errChain error

	currentMachines, err := clusterClient.Machines()
	if err != nil {
		return fmt.Errorf("error getting machines: %s", err)
	}

	timeout := viper.GetDuration(sshTimeoutFlag)

	for name, machine := range clusterClient.ConfiguredMachines() {
		machineState, ok := currentMachines[name]
		if !ok {
			printMachineStatus("SSH", name, machine, false)
			errChain = multierror.Append(errChain, fmt.Errorf(
				"machine does not exists in state: %s",
				name,
			))
			continue
		}

		machineClient := clusterClient.MachineClient(machineState)

		if err := machineClient.WaitForSSH(timeout); err != nil {
			printMachineStatus("SSH", name, machine, false)
			errChain = multierror.Append(errChain, fmt.Errorf(
				"ssh status failed for %s: %w",
				name, err,
			))
			continue
		}

		printMachineStatus("SSH", name, machine, true)
	}

	return errChain
}

func statusNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var errChain error

	for name, machine := range clusterClient.ConfiguredMachines() {
		if machine.NodeType == api.Worker || machine.NodeType == api.Master {
			exists, err := clusterClient.NodeExists(name)
			if err != nil {
				printMachineStatus("K8S node", name, machine, false)
				errChain = multierror.Append(errChain, fmt.Errorf(
					"node status failed for %s: %w",
					name, err,
				))
				continue
			} else if !exists {
				printMachineStatus("K8S node", name, machine, false)
				errChain = multierror.Append(errChain, fmt.Errorf(
					"node does not exist in Kubernetes: %s",
					name,
				))
				continue
			}
			printMachineStatus("K8S node", name, machine, true)
		}
	}

	return errChain
}
