package runner

import (
	"fmt"
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testS3CmdConfig = &S3CmdConfig{
		CloudProviderName:         "cloud",
		S3cfgPath:                 "s3cfg",
		ManageS3BucketsScriptPath: "manage-s3-buckets.sh",
		Buckets:                   map[string]string{"A": "B", "C": "d"},
	}
)

func testS3CmdCreate(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"s3cmd_create",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", "--no-fifo", testS3CmdConfig.S3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --create",
			testS3CmdConfig.ManageS3BucketsScriptPath,
		),
	)
	wantCmd.Env = testS3CmdConfig.Buckets
	wantCmd.Env["CLOUD_PROVIDER"] = testS3CmdConfig.CloudProviderName

	r.Push(&TestCommand{Command: wantCmd})

	s3cmd := NewS3Cmd(logger, r, testS3CmdConfig)

	if err := s3cmd.Create(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func testS3CmdAbort(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"s3cmd_abort",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", "--no-fifo", testS3CmdConfig.S3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --abort",
			testS3CmdConfig.ManageS3BucketsScriptPath,
		),
	)
	wantCmd.Env = testS3CmdConfig.Buckets
	wantCmd.Env["CLOUD_PROVIDER"] = testS3CmdConfig.CloudProviderName

	r.Push(&TestCommand{Command: wantCmd})

	s3cmd := NewS3Cmd(logger, r, testS3CmdConfig)

	if err := s3cmd.Abort(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func testS3CmdDelete(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"s3cmd_delete",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "exec-file", "--no-fifo", testS3CmdConfig.S3cfgPath,
		fmt.Sprintf(
			"S3COMMAND_CONFIG_FILE={} %s --delete",
			testS3CmdConfig.ManageS3BucketsScriptPath,
		),
	)
	wantCmd.Env = testS3CmdConfig.Buckets
	wantCmd.Env["CLOUD_PROVIDER"] = testS3CmdConfig.CloudProviderName

	r.Push(&TestCommand{Command: wantCmd})

	s3cmd := NewS3Cmd(logger, r, testS3CmdConfig)

	if err := s3cmd.Abort(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}
