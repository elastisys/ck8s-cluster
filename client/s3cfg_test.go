package client

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/api/openstack"
)

func TestRenderS3CfgPlaintextExoscale(t *testing.T) {
	cluster := exoscale.Empty(api.ServiceCluster)
	cluster.S3AccessKey = "a"
	cluster.S3SecretKey = "b"
	cluster.S3RegionAddress = "c"

	want := fmt.Sprintf(`[default]
use_https = True
host_base = %s
host_bucket = %%(bucket)s.%s
access_key = %s
secret_key = %s
`,
		cluster.S3RegionAddress,
		cluster.S3RegionAddress,
		cluster.S3AccessKey,
		cluster.S3SecretKey,
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
	cluster := openstack.Empty(api.ServiceCluster)
	cluster.S3AccessKey = "a"
	cluster.S3SecretKey = "b"
	cluster.S3RegionAddress = "c"

	want := fmt.Sprintf(`[default]
use_https = True
host_base = %s
host_bucket = %s
access_key = %s
secret_key = %s
`,
		cluster.S3RegionAddress,
		cluster.S3RegionAddress,
		cluster.S3AccessKey,
		cluster.S3SecretKey,
	)
	var got bytes.Buffer

	if err := renderS3CfgPlaintext(cluster, &got); err != nil {
		t.Fatal(err)
	}

	if diff := cmp.Diff(want, got.String()); diff != "" {
		t.Errorf("log mismatch (-want +got):\n%s", diff)
	}
}
