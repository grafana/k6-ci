# k6-ci

Reusable CI workflows and a composite GitHub Action that k6 extensions call via `workflow_call` to enforce k6-core standards.

## Architecture

The single reusable workflow is the repo's product. Downstream k6 extensions reference it and inherit dependency verification, linting, multi-version/multi-platform testing, and xk6 build checks. The test module exists only to validate the CI pipeline itself; it implements the k6 module interface but exports nothing.

Data flows outward: extensions call in, and the workflow pulls external artifacts at runtime. The canonical `.golangci.yml` lives here; the composite action at `.github/actions/lint/` downloads it at the caller's pinned ref and optionally applies a `.golangci.patch` from the caller's workspace. The `.github/actions/deps/` composite action handles the `go mod tidy` + optional vendor sync + `go mod verify` check; callers compose it themselves when they need to wire up private-module credentials first. The `extension-build-testing` job installs `xk6` from master, not a pinned version.

Go tip is sourced from `grafana/gotip` GitHub releases. The release tag matches the runner platform name (e.g., `ubuntu-latest`).

## Gotchas

- Go caching is disabled in all CI jobs (`cache: false`) to prevent cache-poisoning. Local builds will always be faster than CI.
- Go tip failures are expected and do not block merges.
- Upstream xk6 changes can break CI without any change in this repo. If CI breaks after a green local build, check that upstream first.
- Line 1 of `.golangci.yml` is the golangci-lint version pin (`# vX.Y.Z`). Tooling reads it; do not remove the comment.
- The test file is intentionally named `mudule_test.go`. Do not rename it.
- The workflow's `skip-extension-testing` input is compared with `!= true` (not `!= 'true'`). GitHub coerces booleans for `workflow_dispatch` but not always for `workflow_call`; callers must pass a real boolean.
- **Self-CI gap on action changes**: `all.yml` references `.github/actions/{deps,lint}` as `grafana/k6-ci/...@main`, not `./`, because `./` resolves to the caller's workspace under workflow_call. Consequence: a PR to k6-ci that modifies one of those actions runs all.yml against the *merged* version of the action, not the PR's. The companion workflow `self-test.yml` uses `./` paths on push/PR to k6-ci and exercises the PR's version. Both should pass before merging an action change.
