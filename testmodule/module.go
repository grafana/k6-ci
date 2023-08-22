// Package testmodule provides no functionality, it just exists to
// test the CI's steps like linting, testing, and building.
package testmodule

import "go.k6.io/k6/js/modules"

type (
	// RootModule .
	RootModule struct{}

	// ModuleInstance .
	ModuleInstance struct{}
)

var (
	_ modules.Module   = &RootModule{}
	_ modules.Instance = &ModuleInstance{}
)

// New .
func New() *RootModule {
	return &RootModule{}
}

// NewModuleInstance .
func (*RootModule) NewModuleInstance(_ modules.VU) modules.Instance {
	return &ModuleInstance{}
}

// Exports returns the exports of the grpc module.
func (mi *ModuleInstance) Exports() modules.Exports {
	return modules.Exports{
		Named: map[string]interface{}{},
	}
}
