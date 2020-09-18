package runner

import (
	"bytes"
	"fmt"

	"io"
	"os"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

type TestCommand struct {
	*Command

	Stdout, Stderr []byte
	ExitCode       int
}

func (c *TestCommand) Diff(t *testing.T, cmd *Command) {
	if diff := cmp.Diff(
		c.Command, cmd,
		// TODO: Check set vs not set
		cmpopts.IgnoreFields(Command{}, "Stdin"),
		cmpopts.IgnoreFields(Command{}, "OutputHandler"),
		cmpopts.IgnoreFields(Command{}, "ExitCodeHandlers"),
	); diff != "" {
		t.Errorf("cmd mismatch (-want +got):\n%s", diff)
	}
}

type TestRunner struct {
	t *testing.T

	cmdQueue []*TestCommand
}

func NewTestRunner(t *testing.T) *TestRunner {
	return &TestRunner{
		t: t,
	}
}

// Push enqueues a command that should be compared to the actual command that
// is executed by the runner.
func (r *TestRunner) Push(cmd *TestCommand) {
	r.cmdQueue = append(r.cmdQueue, cmd)
}

func (r *TestRunner) pop() *TestCommand {
	if len(r.cmdQueue) > 0 {
		cmd := r.cmdQueue[0]
		r.cmdQueue = r.cmdQueue[1:]
		return cmd
	}

	return &TestCommand{}
}

// TODO: Might want to test multiple errors.
func (r *TestRunner) Run(cmd *Command) (err error) {
	want := r.pop()

	want.Diff(r.t, cmd)

	if cmd.OutputHandler != nil {
		err = cmd.OutputHandler(
			bytes.NewReader(want.Stdout),
			bytes.NewReader(want.Stderr),
		)
	}

	if fn, ok := cmd.ExitCodeHandlers[want.ExitCode]; ok {
		err = fn()
	}

	return err
}

func (r *TestRunner) Output(cmd *Command) error {
	return r.Run(cmd)
}

func (r *TestRunner) Background(cmd *Command) error {
	return r.Run(cmd)
}

type TestExecutor struct {
	cmd *TestCommand

	stdin                  io.Reader
	stdout, stderr         io.Writer
	stdoutPipe, stderrPipe io.WriteCloser

	errCh chan error
}

func NewTestExecutorFactory(cmd *TestCommand) ExecutorFactory {
	return func(_ *Command) Executor {
		return &TestExecutor{
			cmd: cmd,

			errCh: make(chan error),
		}
	}
}

func (e *TestExecutor) Start() error {
	go func() {
		if e.stdoutPipe != nil || e.stderrPipe != nil {
			if _, err := e.stdoutPipe.Write(e.cmd.Stdout); err != nil {
				e.errCh <- err
				return
			}
			if err := e.stdoutPipe.Close(); err != nil {
				e.errCh <- err
				return
			}

			if _, err := e.stderrPipe.Write(e.cmd.Stderr); err != nil {
				e.errCh <- err
				return
			}
			if err := e.stderrPipe.Close(); err != nil {
				e.errCh <- err
				return
			}
		} else {
			if _, err := e.stdout.Write(e.cmd.Stdout); err != nil {
				e.errCh <- err
				return
			}
			if _, err := e.stderr.Write(e.cmd.Stderr); err != nil {
				e.errCh <- err
				return
			}
		}

		if e.cmd.ExitCode != 0 {
			e.errCh <- fmt.Errorf("exit code: %d", e.cmd.ExitCode)
		}

		e.errCh <- nil
	}()

	return nil
}

func (e *TestExecutor) Wait() error {
	return <-e.errCh
}

func (e *TestExecutor) Signal(s os.Signal) error {
	// TODO: Test signals
	panic("not implemented")
}

func (e *TestExecutor) StdoutPipe() (io.ReadCloser, error) {
	if e.stdout != nil {
		return nil, fmt.Errorf("stdout already set")
	}

	var r io.ReadCloser
	r, e.stdoutPipe = io.Pipe()
	return r, nil
}

func (e *TestExecutor) StderrPipe() (io.ReadCloser, error) {
	if e.stderr != nil {
		return nil, fmt.Errorf("stderr already set")
	}

	var r io.ReadCloser
	r, e.stderrPipe = io.Pipe()
	return r, nil
}

func (e *TestExecutor) SetStdin(stdin io.Reader) {
	e.stdin = stdin
}

func (e *TestExecutor) SetStdout(stdout io.Writer) {
	e.stdout = stdout
}

func (e *TestExecutor) SetStderr(stderr io.Writer) {
	e.stderr = stderr
}

func (e *TestExecutor) ExitCodeFromError(err error) (int, error) {
	return e.cmd.ExitCode, nil
}
