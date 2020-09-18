package runner

import (
	"io"

	"go.uber.org/zap"
)

type SOPSConfig struct {
	SOPSConfigPath string
}

type SOPS struct {
	runner Runner

	config *SOPSConfig

	logger *zap.Logger
}

func NewSOPS(logger *zap.Logger, runner Runner, config *SOPSConfig) *SOPS {
	return &SOPS{
		runner: runner,

		config: config,

		logger: logger,
	}
}

// EncryptStdin runs `sops -e --config CONFIG --input_type INPUT_TYPE
// --output-type OUTPUT_TYPE /dev/stdin`. This is useful to for encrypting
// data not already stored on the filesystem.
func (s *SOPS) EncryptStdin(
	inputType string,
	outputType string,
	plaintext io.Reader,
	encrypted io.Writer,
) error {
	s.logger.With(
		zap.String("input_type", inputType),
		zap.String("output_type", outputType),
	).Debug("sops_encrypt_stdin")

	cmd := NewCommand(
		"sops", "-e",
		"--config", s.config.SOPSConfigPath,
		"--input-type", inputType,
		"--output-type", outputType,
		"/dev/stdin",
	)

	cmd.Stdin = plaintext

	cmd.OutputHandler = func(stdoutPipe, stderrPipe io.Reader) error {
		if _, err := io.Copy(encrypted, stdoutPipe); err != nil {
			return err
		}
		return nil
	}

	return s.runner.Background(cmd)
}

// EncryptFile runs `sops -e -i --config CONFIG --input_type INPUT_TYPE
// --output-type OUTPUT_TYPE PATH`.
// TODO: This does not verify that the file isn't already encrypted.
// https://github.com/mozilla/sops/issues/460
func (s *SOPS) EncryptFileInPlace(
	inputType string,
	outputType string,
	path string,
) error {
	s.logger.With(
		zap.String("input_type", inputType),
		zap.String("output_type", outputType),
		zap.String("path", path),
	).Debug("sops_encrypt_file_in_place")

	return s.runner.Run(NewCommand(
		"sops", "-e", "-i",
		"--config", s.config.SOPSConfigPath,
		"--input-type", inputType,
		"--output-type", outputType,
		path,
	))
}
