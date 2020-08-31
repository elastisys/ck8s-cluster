package runner

import (
	"io"
	"io/ioutil"
	"strings"

	"go.uber.org/zap"
)

type Kubeadm struct {
	runner Runner

	logger *zap.Logger
}

func NewKubeadm(logger *zap.Logger, runner Runner) *Kubeadm {
	return &Kubeadm{
		runner: runner,

		logger: logger,
	}
}

func (k *Kubeadm) Reset() error {
	k.logger.Debug("kubeadm_reset")
	return k.runner.Run(NewCommand("sudo", "kubeadm", "reset", "--force"))
}

func (k *Kubeadm) Upgrade(version string, autoApprove bool) error {
	k.logger.Debug("kubeadm_upgrade")

	args := []string{"kubeadm", "upgrade", "apply", version}

	if autoApprove {
		args = append(args, "-y")
	}

	return k.runner.Run(NewCommand("sudo", args...))
}

func (k *Kubeadm) Version() (string, error) {
	k.logger.Debug("kubeadm_version")

	var version string

	cmd := NewCommand("kubeadm", "version", "-o", "short")
	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		output, err := ioutil.ReadAll(stdout)
		if err != nil {
			return err
		}

		version = strings.TrimSuffix(string(output), "\n")

		return nil
	}

	return version, k.runner.Background(cmd)
}
