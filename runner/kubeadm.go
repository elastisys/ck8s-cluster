package runner

import "go.uber.org/zap"

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
