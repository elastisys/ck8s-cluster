package client

import (
	"fmt"
	"time"

	"go.uber.org/zap"
	"golang.org/x/crypto/ssh"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/runner"
)

// MachineClient is an SSHClient with extended capabilities such as running
// kubeadm commands and waiting for an SSH server to respond.
type MachineClient struct {
	*SSHClient

	silent bool

	kubeadm *runner.Kubeadm

	baseLogger *zap.Logger
	logger     *zap.Logger
}

func NewMachineClient(
	logger *zap.Logger,
	silent bool,
	machine api.MachineState,
	sshPrivateKeyPath api.Path,
) *MachineClient {
	return &MachineClient{
		SSHClient: NewSSHClient(logger, &SSHClientConfig{
			Host: machine.PublicIP,
			Port: 22,
			User: "ubuntu",

			PrivateKeyPath: sshPrivateKeyPath,
		}),

		silent: silent,

		baseLogger: logger,
		logger: logger.With(
			zap.String("node_type", string(machine.NodeType)),
		),
	}
}

// Reset runs kubeadm reset on the machine.
func (c *MachineClient) Reset() error {
	c.logger.Info("machine_client_reset")

	return c.SingleSession(func(session *ssh.Session) error {
		r := runner.NewSSHRunner(c.baseLogger, session, c.silent)
		return runner.NewKubeadm(c.baseLogger, r).Reset()
	})
}

func (c *MachineClient) WaitForSSH(timeout time.Duration) error {
	logger := c.logger.With(
		zap.Duration("timeout", timeout),
	)

	logger.Info("machine_client_ssh_wait")

	waitUntil := time.Now().Add(timeout)
	for {
		if time.Now().After(waitUntil) {
			break
		}

		if err := c.Connect(); err != nil {
			logger.Debug("machine_client_ssh_wait_retry")
			time.Sleep(1 * time.Second)
		} else {
			c.client.Close()
			return nil
		}
	}

	return fmt.Errorf("timed out waiting for SSH connection")
}
