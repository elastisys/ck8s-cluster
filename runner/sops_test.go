package runner

import (
	"bytes"
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testSOPSConfig = &SOPSConfig{
		SOPSConfigPath: ".sops.yaml",
	}
	testSOPSInputType  = "sops-input-type"
	testSOPSOutputType = "sops-output-type"
	testSOPSFilePath   = "somefile"
)

func TestSOPSEncryptStdin(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"sops_encrypt_stdin",
	})

	r := NewTestRunner(t)

	wantFakeEncrypted := []byte("not really encrypted")

	stdin := bytes.NewReader([]byte("plaintext"))

	wantCmd := NewCommand(
		"sops", "-e",
		"--config", testSOPSConfig.SOPSConfigPath,
		"--input-type", testSOPSInputType,
		"--output-type", testSOPSOutputType,
		"/dev/stdin",
	)
	wantCmd.Stdin = stdin

	var encOut bytes.Buffer

	r.Push(&TestCommand{Command: wantCmd, Stdout: wantFakeEncrypted})

	sops := NewSOPS(logger, r, testSOPSConfig)

	if err := sops.EncryptStdin(
		testSOPSInputType,
		testSOPSOutputType,
		stdin,
		&encOut,
	); err != nil {
		t.Error(err)
	}

	gotFakeEncrypted := encOut.Bytes()

	if !bytes.Equal(wantFakeEncrypted, gotFakeEncrypted) {
		t.Errorf(
			"fake encrypted mismatch, got: %s, want: %s",
			gotFakeEncrypted, wantFakeEncrypted,
		)
	}

	logTest.Diff(t)
}

func TestSOPSEncryptFileInPlace(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"sops_encrypt_file_in_place",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand(
		"sops", "-e", "-i",
		"--config", testSOPSConfig.SOPSConfigPath,
		"--input-type", testSOPSInputType,
		"--output-type", testSOPSOutputType,
		testSOPSFilePath,
	)

	r.Push(&TestCommand{Command: wantCmd})

	sops := NewSOPS(logger, r, testSOPSConfig)

	if err := sops.EncryptFileInPlace(
		testSOPSInputType,
		testSOPSOutputType,
		testSOPSFilePath,
	); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}
