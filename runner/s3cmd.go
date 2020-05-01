package runner

import (
	"fmt"
	"io"
	"text/template"

	"go.uber.org/zap"

	"github.com/elastisys/ck8s/api"
)

type S3Cmd struct {
	runner Runner

	cloudProviderName string

	s3cfgPath                 string
	manageS3BucketsScriptPath string

	buckets map[string]string

	logger *zap.Logger
}

func NewS3Cmd(
	logger *zap.Logger,
	runner Runner,
	cloudProviderName string,
	s3cfgPath string,
	manageS3BucketsScriptPath string,
	buckets map[string]string,
) *S3Cmd {
	return &S3Cmd{
		runner: runner,

		cloudProviderName: cloudProviderName,

		s3cfgPath:                 s3cfgPath,
		manageS3BucketsScriptPath: manageS3BucketsScriptPath,

		buckets: buckets,

		logger: logger,
	}
}

func (s *S3Cmd) Create() error {
	s.logger.Debug("s3cmd_create")

	cmd := NewCommand(
		"sops",
		"exec-file", "--no-fifo", s.s3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --create",
			s.manageS3BucketsScriptPath,
		),
	)

	cmd.Env = s.buckets
	cmd.Env["CLOUD_PROVIDER"] = s.cloudProviderName

	return s.runner.Run(cmd)
}

// TODO: AWS
var s3cfgTemplate = `[default]
use_https = True
host_base = {{ .S3RegionAddress }}
host_bucket = %(bucket)s.{{ .S3RegionAddress }}
access_key = {{ .S3AccessKey }}
secret_key = {{ .S3SecretKey }}
`

func RenderS3CfgPlaintext(cluster api.Cluster, w io.Writer) error {
	tmpl, err := template.New("s3cfg").Parse(s3cfgTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, cluster)
}
