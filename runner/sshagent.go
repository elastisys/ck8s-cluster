package runner

import (
	"bufio"
	"fmt"
	"io"
	"strings"

	"go.uber.org/zap"
)

// sshAgentWrapCommand adds the SSH_AGENT_SOCK environment variable to a
// command so that it can utilize the SSH agent while running.
func sshAgentWrapCommand(authSock string, cmd *Command) *Command {
	cmd.Env["SSH_AUTH_SOCK"] = authSock
	return cmd
}

// SSHAgentRunner wraps a runner and starts an SSH agent while the runner is
// executing a command.
type SSHAgentRunner struct {
	runner Runner

	privateKeyPath string

	sshAgent *SSHAgent

	logger *zap.Logger
}

func NewSSHAgentRunner(
	logger *zap.Logger,
	runner Runner,
	privateKeyPath string,
) *SSHAgentRunner {
	return &SSHAgentRunner{
		runner: runner,

		privateKeyPath: privateKeyPath,

		sshAgent: NewSSHAgent(logger, runner),

		logger: logger,
	}
}

// withSSHAgent starts an SSH agent, adds the private key to the SSH agent and
// adds the SSH_AUTH_SOCK environment variable to the command before running.
// It kills the SSH agent after the command execution is finished.
func (r *SSHAgentRunner) withSSHAgent(
	cmd *Command,
	fn func(*Command) error,
) error {
	authSock, pid, err := r.sshAgent.Start()
	if err != nil {
		return fmt.Errorf("error starting SSH agent: %w", err)
	}
	defer func() {
		if err := r.sshAgent.Kill(pid); err != nil {
			r.logger.Error("ssh_agent_runner_kill_error", zap.Error(err))
		}
	}()

	if err := r.sshAgent.SOPSAddKey(authSock, r.privateKeyPath); err != nil {
		return fmt.Errorf("error adding key to SSH agent: %w", err)
	}

	return fn(sshAgentWrapCommand(authSock, cmd))
}

func (r *SSHAgentRunner) Run(cmd *Command) error {
	return r.withSSHAgent(cmd, r.runner.Run)
}

func (r *SSHAgentRunner) Background(cmd *Command) error {
	return r.withSSHAgent(cmd, r.runner.Background)
}

func (r *SSHAgentRunner) Output(cmd *Command) error {
	return r.withSSHAgent(cmd, r.runner.Output)
}

type SSHAgent struct {
	runner Runner

	logger *zap.Logger
}

func NewSSHAgent(logger *zap.Logger, r Runner) *SSHAgent {
	return &SSHAgent{
		runner: r,

		logger: logger,
	}
}

// Start runs `ssh-agent -c`. Make sure to always run the Kill command to kill
// the ssh-agent process.
func (s *SSHAgent) Start() (authSock, pid string, err error) {
	s.logger.Debug("ssh_agent_start")

	cmd := NewCommand("ssh-agent", "-c")

	// TODO: This is very crude and assumes that the output is exactly:
	//       setenv SSH_AUTH_SOCK /tmp/ssh-.../agent.[pid];
	//       setenv SSH_AGENT_PID [pid];
	//       echo Agent pid [pid];
	cmd.OutputHandler = func(stdout, stderr io.Reader) error {
		scanner := bufio.NewScanner(stdout)

		for scanner.Scan() {
			parts := strings.Split(scanner.Text(), " ")
			if len(parts) == 3 {
				key := parts[1]
				// Strip trailing ;
				value := parts[2][:len(parts[2])-1]

				switch key {
				case "SSH_AUTH_SOCK":
					authSock = value
				case "SSH_AGENT_PID":
					pid = value
				}
			}
		}

		if err := scanner.Err(); err != nil {
			return fmt.Errorf("scanner error: %w", err)
		}

		if authSock == "" {
			return fmt.Errorf("SSH_AUTH_SOCK missing in ssh-agent output")
		}

		if pid == "" {
			return fmt.Errorf("SSH_AGENT_PID missing in ssh-agent output")
		}

		return nil
	}

	err = s.runner.Background(cmd)

	return
}

// SOPSAddKey runs `sops exec-file PRIVATE_KEY 'ssh-add "{}"` which decrypts a
// private SSH key using SOPS and adds it to the SSH agent.
func (s *SSHAgent) SOPSAddKey(authSock, privateKeyPath string) error {
	s.logger.Debug(
		"ssh_agent_sops_add_key",
		zap.String("private_key", privateKeyPath),
	)

	cmd := NewCommand("sops", "exec-file", privateKeyPath, "ssh-add \"{}\"")

	return s.runner.Background(sshAgentWrapCommand(authSock, cmd))
}

// Kill runs `kill PID` to kill the ssh-agent.
func (s *SSHAgent) Kill(pid string) error {
	s.logger.Debug("ssh_agent_kill")
	return s.runner.Background(NewCommand("kill", pid))
}
