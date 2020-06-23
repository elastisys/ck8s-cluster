package runner

import (
	"fmt"

	"go.uber.org/zap"
)

type S3CmdConfig struct {
	CloudProviderName string

	S3cfgPath                 string
	ManageS3BucketsScriptPath string

	Buckets map[string]string
}

type S3Cmd struct {
	runner Runner

	config *S3CmdConfig

	logger *zap.Logger
}

func NewS3Cmd(
	logger *zap.Logger,
	runner Runner,
	config *S3CmdConfig,
) *S3Cmd {
	return &S3Cmd{
		runner: runner,

		config: config,

		logger: logger,
	}
}

func (s *S3Cmd) command(flag string) *Command {
	cmd := NewCommand(
		"sops",
		"exec-file", "--no-fifo", s.config.S3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s %s",
			s.config.ManageS3BucketsScriptPath,
			flag,
		),
	)

	cmd.Env = s.config.Buckets
	cmd.Env["CLOUD_PROVIDER"] = s.config.CloudProviderName

	return cmd
}

func (s *S3Cmd) Create() error {
	s.logger.Debug("s3cmd_create")
	return s.runner.Run(s.command("--create"))
}

func (s *S3Cmd) Abort() error {
	s.logger.Debug("s3cmd_abort")
	return s.runner.Run(s.command("--abort"))
}

func (s *S3Cmd) Delete() error {
	s.logger.Debug("s3cmd_delete")
	return s.runner.Run(s.command("--delete"))
}
