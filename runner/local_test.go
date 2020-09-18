package runner

import (
	"os"
	"os/exec"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
)

func TestLocalExecutor(t *testing.T) {
	want := exec.Command("test", "foo", "bar")
	want.Dir = "/tmp"
	want.Env = os.Environ()
	want.Env = append(want.Env, "foo=bar")

	got := NewLocalExecutor(&Command{
		Name: "test",
		Args: []string{"foo", "bar"},
		Dir:  "/tmp",
		Env:  map[string]string{"foo": "bar"},
	})

	if diff := cmp.Diff(
		want, got.(*LocalExecutor).Cmd,
		cmpopts.IgnoreUnexported(exec.Cmd{}),
	); diff != "" {
		t.Errorf("cmd mismatch (-want +got):\n%s", diff)
	}
}
