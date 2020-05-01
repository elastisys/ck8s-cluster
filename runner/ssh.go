package runner

import (
	"errors"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"syscall"

	"go.uber.org/zap"
	"golang.org/x/crypto/ssh"
)

// NewSSHRunner returns a StandardRunner which runs commands using a
// LocalExecutor. It assumes the session stays open for the entirety of the
// run.
func NewSSHRunner(
	logger *zap.Logger,
	session *ssh.Session,
	defaultToBackground bool,
) *StandardRunner {
	return NewStandardRunner(logger, func(cmd *Command) Executor {
		return NewSSHExecutor(session, cmd)
	}, defaultToBackground)
}

type SSHExecutor struct {
	*ssh.Session

	cmd string
}

func NewSSHExecutor(s *ssh.Session, cmd *Command) *SSHExecutor {
	// TODO: Should probably never be needed but I guess we could start all
	// 		 commands with cd cmd.Dir &&?
	if cmd.Dir != "" {
		panic("the SSHExecutor does not currently support Command.Dir")
	}

	for name, value := range cmd.Env {
		s.Setenv(name, value)
	}

	return &SSHExecutor{
		Session: s,

		cmd: cmd.Name + " " + strings.Join(cmd.Args, " "),
	}
}

func (e *SSHExecutor) Start() error {
	return e.Session.Start(e.cmd)
}

func (e *SSHExecutor) StdoutPipe() (io.ReadCloser, error) {
	pipe, err := e.Session.StdoutPipe()
	return ioutil.NopCloser(pipe), err
}

func (e *SSHExecutor) StderrPipe() (io.ReadCloser, error) {
	pipe, err := e.Session.StderrPipe()
	return ioutil.NopCloser(pipe), err
}

func (e *SSHExecutor) Signal(localSignal os.Signal) error {
	var remoteSignal ssh.Signal
	switch localSignal {
	case syscall.SIGINT:
		fallthrough
	case os.Interrupt:
		remoteSignal = ssh.SIGINT
	}
	return e.Session.Signal(remoteSignal)
}

func (e *SSHExecutor) SetStdin(stdin io.Reader) {
	e.Session.Stdin = stdin
}

func (e *SSHExecutor) SetStdout(stdout io.Writer) {
	e.Session.Stdout = stdout
}

func (e *SSHExecutor) SetStderr(stderr io.Writer) {
	e.Session.Stderr = stderr
}

func (e *SSHExecutor) ExitCodeFromError(err error) (int, error) {
	var exitErr *ssh.ExitError
	if errors.As(err, &exitErr) {
		return exitErr.Waitmsg.ExitStatus(), nil
	}

	return -1, NoExitCodeErr
}
