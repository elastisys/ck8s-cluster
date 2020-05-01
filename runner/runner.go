package runner

import (
	"io"
	"os"

	"go.uber.org/zap/zapcore"
)

type Runner interface {
	Run(*Command) error
	Output(*Command) error
	Background(*Command) error
}

type ExecutorFactory func(*Command) Executor

type Executor interface {
	Start() error
	Wait() error
	Signal(os.Signal) error
	StdoutPipe() (io.ReadCloser, error)
	StderrPipe() (io.ReadCloser, error)
	SetStdin(io.Reader)
	SetStdout(io.Writer)
	SetStderr(io.Writer)
	ExitCodeFromError(error) (int, error)
}

type OutputHandler = func(stdoutPipe, stderrPipe io.Reader) error
type ExitCodeHandler = func() error

type Command struct {
	Name             string
	Args             []string
	Dir              string
	Env              map[string]string
	OutputHandler    OutputHandler
	ExitCodeHandlers map[int]ExitCodeHandler
	// TODO: Stdin is currently not tested.
	Stdin io.Reader
}

func NewCommand(name string, args ...string) *Command {
	return &Command{
		Name:             name,
		Args:             args,
		Env:              make(map[string]string),
		ExitCodeHandlers: make(map[int]ExitCodeHandler),
	}
}

func (c *Command) MarshalLogObject(enc zapcore.ObjectEncoder) error {
	enc.AddString("name", c.Name)
	// TODO: We might want to log args and env as well but then we need to make
	//		 sure we add sanitization.
	return nil
}
