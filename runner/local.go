package runner

import (
	"errors"
	"io"
	"os"
	"os/exec"

	"go.uber.org/zap"
)

// NewLocalRunner returns a StandardRunner which runs commands using a
// LocalExecutor.
func NewLocalRunner(
	logger *zap.Logger,
	defaultToBackground bool,
) *StandardRunner {
	return NewStandardRunner(logger, NewLocalExecutor, defaultToBackground)
}

type LocalExecutor struct {
	*exec.Cmd
}

func NewLocalExecutor(cmd *Command) Executor {
	localCmd := exec.Command(cmd.Name, cmd.Args...)

	localCmd.Dir = cmd.Dir

	localCmd.Env = os.Environ()

	for name, value := range cmd.Env {
		localCmd.Env = append(localCmd.Env, name+"="+value)
	}

	return &LocalExecutor{localCmd}
}

func (e *LocalExecutor) SetStdin(stdin io.Reader) {
	e.Stdin = stdin
}

func (e *LocalExecutor) SetStdout(stdout io.Writer) {
	e.Stdout = stdout
}

func (e *LocalExecutor) SetStderr(stderr io.Writer) {
	e.Stderr = stderr
}

func (e *LocalExecutor) Signal(s os.Signal) error {
	return e.Process.Signal(s)
}

func (e *LocalExecutor) ExitCodeFromError(err error) (int, error) {
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return exitErr.ExitCode(), nil
	}

	return -1, NoExitCodeErr
}
