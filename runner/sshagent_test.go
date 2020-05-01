package runner

import (
	"fmt"
	"testing"

	"github.com/elastisys/ck8s/testutil"
)

var (
	testSSHAgentPid      = "123"
	testSSHAgentAuthSock = "/tmp/ssh-xyz/agent." + testSSHAgentPid
	testSSHAgentStdout   = []byte(fmt.Sprintf(`setenv SSH_AUTH_SOCK %s;
setenv SSH_AGENT_PID %s;
echo Agent pid %s;
`,
		testSSHAgentAuthSock,
		testSSHAgentPid,
		testSSHAgentPid,
	))
	testSSHAgentPrivateKeyPath = "privkey"
)

func TestSSHAgentRunner(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"ssh_agent_start",
		"ssh_agent_sops_add_key",
		"ssh_agent_kill",
	})

	r := NewTestRunner(t)

	r.Push(&TestCommand{
		Command: NewCommand("ssh-agent", "-c"),
		Stdout:  testSSHAgentStdout,
	})

	wantCmd := NewCommand(
		"sops", "exec-file", testSSHAgentPrivateKeyPath,
		"ssh-add \"{}\"",
	)
	wantCmd.Env = map[string]string{
		"SSH_AUTH_SOCK": testSSHAgentAuthSock,
	}
	r.Push(&TestCommand{Command: wantCmd})

	wantCmd = NewCommand("test")
	wantCmd.Env = map[string]string{
		"SSH_AUTH_SOCK": testSSHAgentAuthSock,
	}
	r.Push(&TestCommand{Command: wantCmd})

	r.Push(&TestCommand{Command: NewCommand("kill", testSSHAgentPid)})

	s := NewSSHAgentRunner(logger, r, testSSHAgentPrivateKeyPath)

	if err := s.Run(NewCommand("test")); err != nil {
		t.Error(err)
	}

	logTest.Diff(t)
}

func TestSSHAgentStartInvalidOutput(t *testing.T) {
	logTest, logger := testutil.NewTestLogger([]string{
		"ssh_agent_start",
	})

	r := NewTestRunner(t)

	r.Push(&TestCommand{
		Command: NewCommand("ssh-agent", "-c"),
		Stdout:  []byte("bad output"),
	})

	if _, _, err := NewSSHAgent(logger, r).Start(); err == nil {
		t.Error("expected error")
	}

	logTest.Diff(t)
}
