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

func printMachineStatus(name string, machine api.Machine, success bool) {
	status := Green.Fmt("✔️")
	if !success {
		status = Red.Fmt("❌")
	}
	fmt.Println(fmt.Sprintf(
		"%s %s %s %s",
		name,
		machine.NodeType.String(),
		machine.Name,
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

func machineExists(
	machine api.Machine,
	currentMachines []api.MachineState,
) (api.MachineState, error) {
	var errChain error

	for _, machineState := range currentMachines {
		if machine == machineState.Machine {
			return machineState, nil
		}
	}
	errChain = multierror.Append(errChain, fmt.Errorf(
		"machine does not exists in state: %s",
		machine,
	))

	return api.MachineState{}, errChain
}

func statusSSH(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var errChain error

	currentMachines, err := clusterClient.CurrentMachines()
	if err != nil {
		return fmt.Errorf("error getting machines: %s", err)
	}

	timeout := viper.GetDuration(sshTimeoutFlag)

	for _, machine := range clusterClient.DesiredMachines() {
		machineState, err := machineExists(machine, currentMachines)
		if err != nil {
			printMachineStatus("SSH", machine, false)
			errChain = multierror.Append(errChain, err)
			continue
		}

		machineClient := clusterClient.MachineClient(machineState)

		if err := machineClient.WaitForSSH(timeout); err != nil {
			printMachineStatus("SSH", machine, false)
			errChain = multierror.Append(fmt.Errorf(
				"ssh status failed for %s: %w",
				machineState.Name, err,
			))
			continue
		}

		printMachineStatus("SSH", machine, true)
	}

	return errChain
}

func statusNode(
	clusterClient *client.ClusterClient,
	cmd *cobra.Command,
	args []string,
) error {
	var errChain error

	for _, machine := range clusterClient.DesiredMachines() {
		exists, err := clusterClient.NodeExists(machine.Name)
		if err != nil {
			printMachineStatus("K8S node", machine, false)
			errChain = multierror.Append(fmt.Errorf(
				"node status failed for %s: %w",
				machine.Name, err,
			))
			continue
		} else if !exists {
			printMachineStatus("K8S node", machine, false)
			errChain = multierror.Append(fmt.Errorf(
				"node does not exist in Kubernetes: %s",
				machine,
			))
			continue
		}
		printMachineStatus("K8S node", machine, true)
	}

	return errChain
}
