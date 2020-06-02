package client

import (
	"html/template"
	"io"

	"github.com/elastisys/ck8s/api"
)

// TODO: AWS
var s3cfgTemplate = `[default]
use_https = True
host_base = {{ .S3RegionAddress }}
host_bucket = %(bucket)s.{{ .S3RegionAddress }}
access_key = {{ .S3AccessKey }}
secret_key = {{ .S3SecretKey }}
`

func renderS3CfgPlaintext(cluster api.Cluster, w io.Writer) error {
	tmpl, err := template.New("s3cfg").Parse(s3cfgTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, cluster)
}
