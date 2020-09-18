package runner

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testOutputHandlerLogMsg = "test_output_handler"
	testOutputHandlerErr    = errors.New("testOutputHandlerErr")

	testExitCodeHandlerLogMsg = "test_exit_code_handler"
	testExitCodeHandlerErr    = errors.New("testExitCodeHandlerErr")
)

type StandardRunnerTestCaseMethod int

const (
	MethodBackground StandardRunnerTestCaseMethod = iota
	MethodOutput
)

type StandardRunnerTestCase struct {
	ExitCode            int
	Background          bool
	WithOutputHandler   bool
	OutputHandlerFail   bool
	WithExitCodeHandler bool
	ExitCodeHandlerFail bool
}

func TestCommandRunner(t *testing.T) {
	// Generate all test case combinations
	// var testCases = []TestCase{
	// 	{0, false, false, false, false, false},
	// 	{0, true, false, false, false, false},
	// 	{0, false, true, false, false, false},
	//  ...
	// 	{2, true, true, true, true, true},
	// }
	var testCases []StandardRunnerTestCase
	for exitCode := 0; exitCode <= 2; exitCode++ {
		for i := 0; i < 32; i++ {
			testCases = append(testCases, StandardRunnerTestCase{
				exitCode,
				((1 << 0) & i) != 0,
				((1 << 1) & i) != 0,
				((1 << 2) & i) != 0,
				((1 << 3) & i) != 0,
				((1 << 4) & i) != 0,
			})
		}
	}

	for _, tc := range testCases {
		// Skip invalid cases
		if !tc.WithOutputHandler && tc.OutputHandlerFail {
			continue
		} else if !tc.WithExitCodeHandler && tc.ExitCodeHandlerFail {
			continue
		}

		name := fmt.Sprintf("ExitCode%d", tc.ExitCode)
		if tc.Background {
			name += "_Background"
		} else {
			name += "_Output"
		}
		if tc.WithOutputHandler {
			name += "_OutputHandler"
		}
		if tc.OutputHandlerFail {
			name += "_OutputHandlerFail"
		}
		if tc.WithExitCodeHandler {
			name += "_WithExitCodeHandler"
		}
		if tc.ExitCodeHandlerFail {
			name += "_ExitCodeHandlerFail"
		}

		t.Run(name, func(t *testing.T) {
			runStandardRunnerTestCase(t, tc)
		})
	}
}

func shouldReturnError(tc StandardRunnerTestCase) bool {
	// An error should always be returned if the output handler has an error.
	if tc.OutputHandlerFail {
		return true
	}

	// An error should be returned if the command fails and no exit code
	// handler is registered for that exit code. However, an error should be
	// returned if the exit code handler also has an error.
	if tc.ExitCode != 0 &&
		(!tc.WithExitCodeHandler || tc.ExitCodeHandlerFail) {
		return true
	}

	return false
}

func runStandardRunnerTestCase(t *testing.T, tc StandardRunnerTestCase) {
	var (
		wantErr           *RunnerError
		wantErrorsInChain []error

		gotErr                 error
		gotOutputHandlerStdout bytes.Buffer
		gotOutputHandlerStderr bytes.Buffer
	)

	cmd := &TestCommand{
		Command:  NewCommand(""),
		Stdout:   []byte(fmt.Sprintf("stdout %d", tc.ExitCode)),
		Stderr:   []byte(fmt.Sprintf("stderr %d", tc.ExitCode)),
		ExitCode: tc.ExitCode,
	}

	if shouldReturnError(tc) {
		if tc.Background {
			wantErr = NewRunnerError(nil)
			wantErr.Stdout = cmd.Stdout
			wantErr.Stderr = cmd.Stderr
		} else {
			wantErr = NewRunnerError(nil)
		}
	}

	logTest, logger := testutil.NewTestLogger(nil)

	if tc.Background {
		logTest.Add("standard_runner_background")
	} else {
		logTest.Add("standard_runner_output")
	}

	if tc.WithOutputHandler {
		logTest.Add("standard_runner_output_handler")
		logTest.Add(testOutputHandlerLogMsg)

		if tc.OutputHandlerFail {
			wantErrorsInChain = append(wantErrorsInChain, testOutputHandlerErr)
		}

		cmd.OutputHandler = func(stdoutPipe, stderrPipe io.Reader) error {
			logger.Debug(testOutputHandlerLogMsg)

			if _, err := io.Copy(
				&gotOutputHandlerStdout,
				stdoutPipe,
			); err != nil {
				return err
			}

			if _, err := io.Copy(
				&gotOutputHandlerStderr,
				stderrPipe,
			); err != nil {
				return err
			}

			// TODO: Test "fail early" vs "fail late"?
			//		 If fail early the runnerError stdout/stderr is different.
			if tc.OutputHandlerFail {
				return testOutputHandlerErr
			}

			return nil
		}
	}

	if tc.WithExitCodeHandler {
		if tc.ExitCode != 0 {
			logTest.Add("standard_runner_exit_code_handler")
			logTest.Add(testExitCodeHandlerLogMsg)

			if tc.ExitCodeHandlerFail {
				wantErrorsInChain = append(
					wantErrorsInChain,
					testExitCodeHandlerErr,
				)
			}
		}

		// TODO: Test exit code handler not registered for cmd.ExitCode?
		cmd.ExitCodeHandlers[cmd.ExitCode] = func() error {
			logger.Debug(testExitCodeHandlerLogMsg)

			if tc.ExitCodeHandlerFail {
				return testExitCodeHandlerErr
			}

			return nil
		}
	}

	executorFactory := NewTestExecutorFactory(cmd)

	runner := NewStandardRunner(logger, executorFactory, tc.Background)

	if tc.Background {
		gotErr = runner.Run(cmd.Command)
	} else {
		stdoutCh, stopStdoutPipe := pipeOSOutput(t, &os.Stdout)
		stderrCh, stopStderrPipe := pipeOSOutput(t, &os.Stderr)

		gotErr = runner.Run(cmd.Command)

		stopStdoutPipe()
		stopStderrPipe()

		stdout := <-stdoutCh
		stderr := <-stderrCh

		if !bytes.Equal(cmd.Stdout, stdout) {
			t.Errorf("stdout mismatch, want: %s, got: %s", cmd.Stdout, stdout)
		}

		if !bytes.Equal(cmd.Stderr, stderr) {
			t.Errorf("stderr mismatch, want: %s, got: %s", cmd.Stderr, stderr)
		}
	}

	if tc.WithOutputHandler {
		if !bytes.Equal(cmd.Stdout, gotOutputHandlerStdout.Bytes()) {
			t.Errorf(
				"output handler stdout mismatch, want: %s, got: %s",
				cmd.Stdout, gotOutputHandlerStdout.String(),
			)
		}

		if !bytes.Equal(cmd.Stderr, gotOutputHandlerStderr.Bytes()) {
			t.Errorf(
				"output handler stderr mismatch, want: %s, got: %s",
				cmd.Stderr, gotOutputHandlerStderr.String(),
			)
		}
	}

	gotRunnerErr := &RunnerError{}
	if wantErr == nil {
		if gotErr != nil {
			t.Error(gotErr)
		}
	} else if !errors.As(gotErr, &gotRunnerErr) {
		t.Error("expected RunnerError")
	} else {
		opts := cmpopts.IgnoreUnexported(RunnerError{})
		if diff := cmp.Diff(wantErr, gotRunnerErr, opts); diff != "" {
			t.Errorf("error mismatch (-want +got):\n%s", diff)
		}
	}

	for _, err := range wantErrorsInChain {
		if !errors.Is(gotErr, err) {
			t.Errorf("missing %s in error chain", err.Error())
		}
	}

	logTest.Diff(t)
}

func pipeOSOutput(t *testing.T, f **os.File) (chan []byte, func()) {
	ch := make(chan []byte)

	old := *f

	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("error creating pipe")
	}

	stop := func() {
		w.Close()
		*f = old
	}

	*f = w

	go func() {
		var buf bytes.Buffer
		io.Copy(&buf, r)
		ch <- buf.Bytes()
	}()

	return ch, stop
}
