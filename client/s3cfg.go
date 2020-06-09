package client

import (
	"html/template"
	"io"

	"github.com/elastisys/ck8s/api"
)

var exoscaleS3Template = `[default]
use_https = True
host_base = {{ .S3RegionAddress }}
host_bucket = %(bucket)s.{{ .S3RegionAddress }}
access_key = {{ .S3AccessKey }}
secret_key = {{ .S3SecretKey }}
`

var openstackS3Template = `[default]
use_https = True
host_base = {{ .S3RegionAddress }}
host_bucket = {{ .S3RegionAddress }}
access_key = {{ .S3AccessKey }}
secret_key = {{ .S3SecretKey }}
`
var awsS3Template = `[default]
access_key = {{ .S3AccessKey }}
secret_key = {{ .S3SecretKey }}
use_https = True
bucket_location = {{ .S3RegionAddress }}
`

var s3cfgTemplates = map[api.CloudProviderType]string{
	api.Exoscale:   exoscaleS3Template,
	api.Openstack:  openstackS3Template,
	api.Safespring: openstackS3Template,
	api.AWS:        awsS3Template,
}

func renderS3CfgPlaintext(cluster api.Cluster, w io.Writer) error {
	cloudProvider := cluster.CloudProvider()
	s3cfgTemplate, ok := s3cfgTemplates[cloudProvider]
	if !ok {
		return api.NewUnsupportedCloudProviderError(cloudProvider)
	}
	tmpl, err := template.New("s3cfg").Parse(s3cfgTemplate)
	if err != nil {
		return err
	}

	return tmpl.Execute(w, cluster)
}
