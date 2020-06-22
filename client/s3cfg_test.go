package client

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/citycloud"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/openstack"
	"github.com/elastisys/ck8s/api/safespring"
)

func TestRenderS3CfgPlaintextExoscale(t *testing.T) {
	cluster := exoscale.Default(api.ServiceCluster, "testName")
	config, ok := cluster.Config().(*exoscale.ExoscaleConfig)
	if !ok {
		panic("WRONG TYPE")
	}
	secret, ok := cluster.Secret().(*exoscale.ExoscaleSecret)
	if !ok {
		panic("WRONG TYPE")
	}
	secret.S3AccessKey = "a"
	secret.S3SecretKey = "b"
	config.S3RegionAddress = "c"

	want := fmt.Sprintf(`[default]
use_https = True
host_base = %s
host_bucket = %%(bucket)s.%s
access_key = %s
secret_key = %s
`,
		config.S3RegionAddress,
		config.S3RegionAddress,
		secret.S3AccessKey,
		secret.S3SecretKey,
	)
	var got bytes.Buffer

	if err := renderS3CfgPlaintext(cluster, &got); err != nil {
		t.Fatal(err)
	}

	if diff := cmp.Diff(want, got.String()); diff != "" {
		t.Errorf("log mismatch (-want +got):\n%s", diff)
	}
}

func TestRenderS3CfgPlaintextOpenstack(t *testing.T) {
	for _, cluster := range []api.Cluster{
		safespring.Default(api.ServiceCluster, "testName"),
		citycloud.Default(api.ServiceCluster, "testName"),
	} {
		config, ok := cluster.Config().(*openstack.OpenstackConfig)
		if !ok {
			panic("WRONG TYPE")
		}
		secret, ok := cluster.Secret().(*openstack.OpenstackSecret)
		if !ok {
			panic("WRONG TYPE")
		}
		secret.S3AccessKey = "a"
		secret.S3SecretKey = "b"
		config.S3RegionAddress = "c"

		want := fmt.Sprintf(`[default]
use_https = True
host_base = %s
host_bucket = %s
access_key = %s
secret_key = %s
`,
			config.S3RegionAddress,
			config.S3RegionAddress,
			secret.S3AccessKey,
			secret.S3SecretKey,
		)
		var got bytes.Buffer

		if err := renderS3CfgPlaintext(cluster, &got); err != nil {
			t.Fatal(err)
		}

		if diff := cmp.Diff(want, got.String()); diff != "" {
			t.Errorf("log mismatch (-want +got):\n%s", diff)
		}
	}
}
