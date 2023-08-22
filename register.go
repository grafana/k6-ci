// Package test .
package test

import (
	"github.com/grafana/k6-ci/testmodule"
	"go.k6.io/k6/js/modules"
)

func init() {
	modules.Register("k6/x/test", new(testmodule.RootModule))
}
