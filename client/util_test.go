package client

import (
	"testing"
)

func TestSplitPath(t *testing.T) {
	type wantParts struct {
		path string
		name string
		ext  string
	}
	tests := map[string]wantParts{
		"/tmp/test.sh": {"/tmp/", "test", "sh"},
		"/tmp/test":    {"/tmp/", "test", ""},
		"tmp/test.sh":  {"tmp/", "test", "sh"},
		"test.sh":      {"", "test", "sh"},
		"test":         {"", "test", ""},
		"":             {"", "", ""},
	}
	for path, want := range tests {
		path, name, ext := splitPath(path)
		if path != want.path || name != want.name || ext != want.ext {
			t.Errorf(
				"want: '%s' '%s' '%s' got: '%s' '%s' '%s'",
				want.path, want.name, want.ext,
				path, name, ext,
			)
		}
	}
}
