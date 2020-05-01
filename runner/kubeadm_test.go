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
