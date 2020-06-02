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

func (s *S3Cmd) Create() error {
	s.logger.Debug("s3cmd_create")

	cmd := NewCommand(
		"sops",
		"exec-file", "--no-fifo", s.config.S3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --create",
			s.config.ManageS3BucketsScriptPath,
		),
	)

	cmd.Env = s.config.Buckets
	cmd.Env["CLOUD_PROVIDER"] = s.config.CloudProviderName

	return s.runner.Run(cmd)
}
