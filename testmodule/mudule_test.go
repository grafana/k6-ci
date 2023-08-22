package testmodule_test

import (
	"testing"

	"github.com/grafana/k6-ci/testmodule"
)

func TestNew(t *testing.T) {
	t.Parallel()

	rootModule := testmodule.New()
	if rootModule == nil {
		t.Error("New() returned nil")
	}
}
