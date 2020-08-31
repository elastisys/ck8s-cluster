package runner

import (
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

func TestKubeadmReset(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubeadm_reset",
	})

	r := NewTestRunner(t)

	wantCmd := NewCommand("sudo", "kubeadm", "reset", "--force")

	r.Push(&TestCommand{Command: wantCmd})

	k := NewKubeadm(logger, r)

	if err := k.Reset(); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubeadmUpgrade(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubeadm_upgrade",
		"kubeadm_upgrade",
	})

	r := NewTestRunner(t)

	version := "v1.16.2"

	k := NewKubeadm(logger, r)

	wantCmd := NewCommand("sudo", "kubeadm", "upgrade", "apply", version)
	r.Push(&TestCommand{Command: wantCmd})

	if err := k.Upgrade(version, false); err != nil {
		t.Error(err)
	}

	wantCmd = NewCommand("sudo", "kubeadm", "upgrade", "apply", version, "-y")
	r.Push(&TestCommand{Command: wantCmd})

	if err := k.Upgrade(version, true); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestKubeadmVersion(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"kubeadm_version",
	})

	r := NewTestRunner(t)

	want := "v1.16.2"

	wantCmd := NewCommand("kubeadm", "version", "-o", "short")

	r.Push(&TestCommand{
		Command: wantCmd,
		Stdout:  []byte(want),
	})

	k := NewKubeadm(logger, r)

	got, err := k.Version()
	if err != nil {
		t.Error(err)
	}

	if got != want {
		t.Errorf("version mismatch got: %s, want: %s", got, want)
	}

	logTest.Diff(t)
}
