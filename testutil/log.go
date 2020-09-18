package testutil

import (
	"testing"

	"github.com/google/go-cmp/cmp"
	"go.uber.org/zap"
	"go.uber.org/zap/zaptest/observer"
)

type TestLogger struct {
	*observer.ObservedLogs

	want []string
}

func NewTestLogger(want []string) (*TestLogger, *zap.Logger) {
	zapCore, observedLogs := observer.New(zap.DebugLevel)

	TestLogger := &TestLogger{
		ObservedLogs: observedLogs,
		want:         want,
	}

	return TestLogger, zap.New(zapCore)
}

func (l *TestLogger) Add(msg string) {
	l.want = append(l.want, msg)
}

func (l *TestLogger) Diff(t *testing.T) {
	var got []string
	for _, logEntry := range l.All() {
		got = append(got, logEntry.Message)
	}

	if diff := cmp.Diff(l.want, got); diff != "" {
		t.Errorf("log mismatch (-want +got):\n%s", diff)
	}
}
