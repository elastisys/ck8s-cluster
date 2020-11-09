package runner

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"strings"

	"go.uber.org/zap"
	"k8s.io/apimachinery/pkg/version"
)

var NodeNotFoundErr = errors.New("kubernetes node not found")
var ServerVersionMissingErr = errors.New("server version missing in output")

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
func (k *Kubectl) NodeExists(name string, addPrefix bool) error {
	k.logger.Debug("kubectl_node_exists")

	if addPrefix {
		name = k.fullNodeName(name)
	}
	cmd := k.command("get", "node", (name))

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

// DeleteAllTimeout runs `sops exec-file KUBECONFIG 'kubectl delete RESOURCE -A --all --timeout=TIMEOUTs EXTRAARGS...'
func (k *Kubectl) DeleteAllTimeout(resource string, timeout int, extraArgs ...string) error {
	k.logger.Debug("kubectl_delete_all_timeout", zap.String("resource", resource))
	args := append([]string{
		"delete",
		resource,
		"-A",
		"--all",
		fmt.Sprintf("--timeout=%ds", timeout),
	}, extraArgs...)

	cmd := k.command(args...)

	var errorOutput []byte
	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		var err error
		errorOutput, err = ioutil.ReadAll(stderr)
		return err
	}
	cmd.ExitCodeHandlers[1] = func() error {
		if !strings.Contains(string(errorOutput), "timed out") {
			return fmt.Errorf("expected no error or timeout, got non timeout error")
		}

		return nil
	}

	return k.runner.Run(cmd)
}

// DeleteAll runs `sops exec-file KUBECONFIG 'kubectl get --raw /api --request-timeout=2s'
func (k *Kubectl) IsUp() bool {
	k.logger.Debug("kubectl_is_up")
	return k.runner.Background(k.command("get", "--raw", "/api", "--request-timeout=2s")) == nil
}

// ServerVersion returns the version of the Kubernetes API server.
func (k *Kubectl) ServerVersion() (string, error) {
	k.logger.Debug("kubectl_server_version")

	type versionOutput struct {
		ServerVersion *version.Info `json:"serverVersion"`
	}

	var output *versionOutput

	cmd := k.command("version", "-o", "json")
	cmd.OutputHandler = func(stdoutPipe, stderrPipe io.Reader) error {
		if err := json.NewDecoder(stdoutPipe).Decode(&output); err != nil {
			return fmt.Errorf("error JSON decoding server version: %w", err)
		}
		return nil
	}

	if err := k.runner.Background(cmd); err != nil {
		return "", err
	}

	if output.ServerVersion == nil {
		return "", ServerVersionMissingErr
	}

	return output.ServerVersion.GitVersion, nil
}
