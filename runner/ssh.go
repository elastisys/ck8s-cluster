package runner

import (
	"bufio"
	"errors"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"syscall"

	"go.uber.org/zap"
	"golang.org/x/crypto/ssh"
)

var osStdinPipeWrite *os.File

func initStdinPipe() {
	// The reason for this stdin piping is to work around an issue where
	// os.Stdin ends up blocked in the SSH session command execution:
	// https://github.com/golang/crypto/blob/94eea52f7b742c7cbe0b03b22f0c4c8631ece122/ssh/session.go#L489
	//
	// The final workaround happens in the SSHExecutor.Wait() where a final
	// write is done on the osStdinPipeWrite to get out of the SSH stdin copy
	// function.
	var err error
	osStdin := os.Stdin
	if os.Stdin, osStdinPipeWrite, err = os.Pipe(); err != nil {
		panic(err)
	}
	go func() {
		r := bufio.NewReader(osStdin)
		for {
			b, err := r.ReadBytes('\n')
			if err != nil {
				if err == io.EOF {
					// TODO: Ignoring EOF for now. Might need to implement
					// support for it if some command requires it.
					continue
				}
				panic(err)
			}
			osStdinPipeWrite.Write(b)
		}
	}()
}

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
	if stdin == os.Stdin {
		// TODO: Once this is turned on we currently can't go back as we will
		// continuously read from stdin. Would be nice if we found a way to
		// restore os.Stdin again.
		initStdinPipe()
		stdin = os.Stdin
	}

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

func (e *SSHExecutor) Wait() error {
	err := e.Session.Wait()
	// We make an extra write here to get out of the stdin copy function.
	// https://github.com/golang/crypto/blob/94eea52f7b742c7cbe0b03b22f0c4c8631ece122/ssh/session.go#L489
	// See initStdinPipe() for full context.
	osStdinPipeWrite.Write([]byte{'\n'})
	return err
}
