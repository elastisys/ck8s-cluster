package runner

import (
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"strings"

	"go.uber.org/zap"
)

var NodeNotFoundErr = errors.New("kubernetes node not found")

type KubectlConfig struct {
	KubeconfigPath string
	NodePrefix     string
}

type Kubectl struct {
	runner Runner

	config *KubectlConfig

	logger *zap.Logger
}

func NewKubectl(
	logger *zap.Logger,
	runner Runner,
	config *KubectlConfig,
) *Kubectl {
	return &Kubectl{
		runner: runner,

		config: config,

		logger: logger.With(
			zap.String("kubeconfig", config.KubeconfigPath),
			zap.String("node_prefix", config.NodePrefix),
		),
	}
}

func (k *Kubectl) command(args ...string) *Command {
	return NewCommand(
		"sops",
		"exec-file", k.config.KubeconfigPath,
		fmt.Sprintf("KUBECONFIG={} kubectl %s", strings.Join(args, " ")),
	)
}

func (k *Kubectl) fullNodeName(name string) string {
	return fmt.Sprintf("%s-%s", k.config.NodePrefix, name)
}

func (k *Kubectl) Command(args []string) error {
	return k.runner.Run(k.command(args...))
}

// NodeExists runs `sops exec-file KUBECONFIG 'kubectl get node NAME'` in the
// background. If the node is not found a NodeNotFoundErr error is returned.
func (k *Kubectl) NodeExists(name string) error {
	k.logger.Debug("kubectl_node_exists")

	cmd := k.command("get", "node", k.fullNodeName(name))

	// TODO: This assumes a lot about the command output. We should replace
	// 		 this with a proper Kubernetes client lib implementation ASAP.
	cmd.OutputHandler = func(stdoutPipe, stderrPipe io.Reader) error {
		stderr, err := ioutil.ReadAll(stderrPipe)
		if err != nil {
			return err
		}
		if strings.Contains(string(stderr), "not found") {
			return NodeNotFoundErr
		}
		return nil
	}

	return k.runner.Background(cmd)
}

// Drain runs `sops exec-file KUBECONFIG 'kubectl drain --ignore-daemonsets
// --delete-local-data NAME'`
func (k *Kubectl) Drain(name string) error {
	k.logger.Debug("kubectl_drain")
	return k.runner.Run(k.command(
		"drain",
		"--ignore-daemonsets",
		"--delete-local-data",
		k.fullNodeName(name),
	))
}

// DeleteNode runs `sops exec-file KUBECONFIG 'kubectl delete node NAME'`
func (k *Kubectl) DeleteNode(name string) error {
	k.logger.Debug("kubectl_delete_node")
	return k.runner.Run(k.command("delete", "node", k.fullNodeName(name)))
}

// DeleteAll runs `sops exec-file KUBECONFIG 'kubectl delete RESOURCE -A --all EXTRAARGS...'
func (k *Kubectl) DeleteAll(resource string, extraArgs ...string) error {
	k.logger.Debug("kubectl_delete_all", zap.String("resource", resource))
	args := append([]string{"delete", resource, "-A", "--all"}, extraArgs...)
	return k.runner.Run(k.command(args...))
}

// DeleteAll runs `sops exec-file KUBECONFIG 'kubectl get --raw /api --request-timeout=2s'
func (k *Kubectl) IsUp() bool {
	k.logger.Debug("kubectl_is_up")
	return k.runner.Background(k.command("get", "--raw", "/api", "--request-timeout=2s")) == nil
}
