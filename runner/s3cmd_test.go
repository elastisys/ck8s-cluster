package runner

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"

	"github.com/elastisys/ck8s/api"
	"github.com/elastisys/ck8s/api/exoscale"
	"github.com/elastisys/ck8s/testutil"
)

var (
	testS3CMDCloudProviderName         = "cloud"
	testS3CMDS3cfgPath                 = "s3cfg"
	testS3CMDManageS3BucketsScriptPath = "manage-s3-buckets.sh"
	testS3CMDBuckets                   = map[string]string{"A": "B", "C": "d"}
)

func TestS3CMDCreate(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"s3cmd_create",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", "--no-fifo", testS3CMDS3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --create",
			testS3CMDManageS3BucketsScriptPath,
		),
	)
	wantCmd.Env = testS3CMDBuckets
	wantCmd.Env["CLOUD_PROVIDER"] = testS3CMDCloudProviderName

	r.Push(&TestCommand{Command: wantCmd})

	s3cmd := NewS3Cmd(
		logger,
		r,
		testS3CMDCloudProviderName,
		testS3CMDS3cfgPath,
		testS3CMDManageS3BucketsScriptPath,
		testS3CMDBuckets,
	)

	if err := s3cmd.Create(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestRenderS3CfgPlaintext(t *testing.T) {
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

	if err := RenderS3CfgPlaintext(cluster, &got); err != nil {
		t.Fatal(err)
	}

	if diff := cmp.Diff(want, got.String()); diff != "" {
		t.Errorf("log mismatch (-want +got):\n%s", diff)
	}
}
