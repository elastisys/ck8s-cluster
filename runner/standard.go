package runner

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"
	"syscall"

	"github.com/hashicorp/go-multierror"
	"go.uber.org/zap"
)

type StandardRunner struct {
	executorFactory ExecutorFactory

	defaultToBackground bool

	caughtSignals []os.Signal

	logger *zap.Logger
}

func NewStandardRunner(
	logger *zap.Logger,
	executorFactory ExecutorFactory,
	defaultToBackground bool,
) *StandardRunner {
	return &StandardRunner{
		executorFactory: executorFactory,

		defaultToBackground: defaultToBackground,

		logger: logger,
	}
}

// Run executes a command using Background or Output depending on the value of
// defaultToBackground.
func (r *StandardRunner) Run(cmd *Command) error {
	if r.defaultToBackground {
		return r.Background(cmd)
	} else {
		return r.Output(cmd)
	}
}

// Background executes a command, writes stdout and stderr to buffers and
// returns them.
func (r *StandardRunner) Background(cmd *Command) error {
	r.logger.Debug(
		"standard_runner_background",
		zap.Object("cmd", cmd),
	)

	var stdout, stderr bytes.Buffer

	if err := r.run(cmd, cmd.Stdin, &stdout, &stderr); err != nil {
		err := NewRunnerError(err)
		err.Stdout = stdout.Bytes()
		err.Stderr = stderr.Bytes()
		return err
	}

	return nil
}

// Output executes a command and pipes os.Stdout, os.Stderr and os.Stdin.
func (r *StandardRunner) Output(cmd *Command) error {
	r.logger.Debug(
		"standard_runner_output",
		zap.Object("cmd", cmd),
	)

	if cmd.Stdin != nil {
		return fmt.Errorf(
			"using Output with a command that has Stdin set is not supported",
		)
	}

	if err := r.run(cmd, os.Stdin, os.Stdout, os.Stderr); err != nil {
		return NewRunnerError(err)
	}

	return nil
}

func (r *StandardRunner) signal(executor Executor, s os.Signal) error {
	r.logger.Debug(
		"standard_runner_signal_process",
		zap.String("signal", s.String()),
	)

	r.caughtSignals = append(r.caughtSignals, s)

	return executor.Signal(s)
}

func (r *StandardRunner) run(
	cmd *Command,
	stdin io.Reader,
	stdout io.Writer,
	stderr io.Writer,
) error {
	var errorChain error

	executor := r.executorFactory(cmd)

	if stdin != nil {
		executor.SetStdin(stdin)
	}

	if cmd.OutputHandler != nil {
		r.logger.Debug("standard_runner_output_handler")

		stdoutPipe, err := executor.StdoutPipe()
		if err != nil {
			return err
		}

		stderrPipe, err := executor.StderrPipe()
		if err != nil {
			return err
		}

		if err := executor.Start(); err != nil {
			return err
		}

		if err := cmd.OutputHandler(
			io.TeeReader(stdoutPipe, stdout),
			io.TeeReader(stderrPipe, stderr),
		); err != nil {
			errorChain = multierror.Append(errorChain, err)
		}
	} else {
		executor.SetStdout(stdout)
		executor.SetStderr(stderr)

		if err := executor.Start(); err != nil {
			return err
		}
	}

	// Forward signals to child process.
	sh := NewSignalsHandler(
		r.logger,
		func(s os.Signal) error {
			return r.signal(executor, s)
		},
		os.Interrupt,
		syscall.SIGTERM,
	)

	err := executor.Wait()

	sh.Close()

	// Return error if any signals are caught. We do this to alert the caller
	// to stop the execution.
	// NOTE(simon): If we ever want to ignore caught signals we could make this
	//              into a specific error type.
	if len(r.caughtSignals) > 0 {
		signalsErr := fmt.Errorf("caught signals: %s", r.caughtSignals)
		errorChain = multierror.Append(signalsErr)
	}

	if err != nil {
		if handled, err2 := r.handleWaitError(cmd, executor, err); !handled {
			if err2 != nil {
				errorChain = multierror.Append(errorChain, err2)
			}

			errorChain = multierror.Append(errorChain, err)
		}
	}

	if errorChain != nil {
		line := cmd.Name
		if len(cmd.Args) > 0 {
			line += " " + strings.Join(cmd.Args, " ")
		}
		return fmt.Errorf("error while executing `%s`: %w", line, errorChain)
	}

	return nil
}

// handleWaitError runs an exit code handler if one is registered on the
// command for the current exit code. It returns handled = true if an exit
// code handler is found and succeeds, else false. An error is returned if the
// executor is not able to determine an exit code from the error or the exit
// code handler fails.
func (r *StandardRunner) handleWaitError(
	cmd *Command,
	executor Executor,
	waitErr error,
) (bool, error) {
	if exitCode, err := executor.ExitCodeFromError(waitErr); err != nil {
		return true, err
	} else if handler, ok := cmd.ExitCodeHandlers[exitCode]; ok {
		r.logger.With(
			zap.Int("exit_code", exitCode),
		).Debug("standard_runner_exit_code_handler")

		if err = handler(); err != nil {
			return false, err
		}

		return true, nil
	}

	return false, nil
}
