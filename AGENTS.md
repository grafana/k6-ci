# k6-ci

Reusable CI workflows and a composite GitHub Action that k6 extensions call via `workflow_call` to enforce k6-core standards.

## Architecture

The single reusable workflow is the repo's product. Downstream k6 extensions reference it and inherit dependency verification, linting, multi-version/multi-platform testing, and xk6 build checks. The test module exists only to validate the CI pipeline itself; it implements the k6 module interface but exports nothing.

Data flows outward: extensions call in, and the workflow pulls external artifacts at runtime. The linter config is fetched from `grafana/k6` master on every run and is gitignored here. The `extension-build-testing` job installs `xk6` from master, not a pinned version.

Go tip is sourced from `grafana/gotip` GitHub releases. The release tag matches the runner platform name (e.g., `ubuntu-latest`).

## Gotchas

- Go caching is disabled in all CI jobs (`cache: false`) to prevent cache-poisoning. Local builds will always be faster than CI.
- Go tip failures are expected and do not block merges.
- Upstream xk6 or golangci-lint config changes can break CI without any change in this repo. If CI breaks after a green local build, check those upstreams first.
- The test file is intentionally named `mudule_test.go`. Do not rename it.
- The workflow's `skip-extension-testing` input is compared with `!= true` (not `!= 'true'`). GitHub coerces booleans for `workflow_dispatch` but not always for `workflow_call`; callers must pass a real boolean.
