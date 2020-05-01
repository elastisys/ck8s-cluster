package runner

import (
	"errors"
	"fmt"
)

var NoExitCodeErr = errors.New("not able to determine exit code from error")

// RunnerError is returned from a Runner when an error occurs during a run,
// with the exception of a successful exit code handler call.
type RunnerError struct {
	Stdout []byte
	Stderr []byte

	err error
}

func NewRunnerError(err error) *RunnerError {
	runnerErr := &RunnerError{
		err: err,
	}

	return runnerErr
}

func (e *RunnerError) Error() string {
	s := e.err.Error()

	if len(e.Stdout) > 0 {
		s = s + fmt.Sprintf("\n\nstdout:\n%s", e.Stdout)
	}

	if len(e.Stderr) > 0 {
		s = s + fmt.Sprintf("\n\nstderr:\n%s", e.Stderr)
	}

	return s
}

func (e *RunnerError) Unwrap() error {
	return e.err
}
