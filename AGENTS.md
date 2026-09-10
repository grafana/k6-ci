# k6-ci

Reusable CI workflows and a composite GitHub Action that k6 extensions call via `workflow_call` to enforce k6-core standards.

## Architecture

The single reusable workflow is the repo's product. Downstream k6 extensions reference it and inherit dependency verification, linting, multi-version/multi-platform testing, and xk6 build checks. The test module exists only to validate the CI pipeline itself; it implements the k6 module interface but exports nothing.

Data flows outward: extensions call in, and the workflow pulls external artifacts at runtime. The canonical `.golangci.yml` lives here; the composite action at `.github/actions/lint/` downloads it at the caller's pinned ref and optionally applies a `.golangci.patch` from the caller's workspace. The `.github/actions/deps/` composite action handles the `go mod tidy` + optional vendor sync + `go mod verify` check; callers compose it themselves when they need to wire up private-module credentials first. The `extension-build-testing` job installs `xk6` from master, not a pinned version.

The current and previous Go versions are defined in `.github/go-versions.env` and exposed by `.github/actions/go-versions/`. Go tip is sourced from `grafana/gotip` GitHub releases. The release tag matches the runner platform name (e.g., `ubuntu-latest`).

## Updating golangci-lint

1. Read the current version from line 1 of `.golangci.yml`. Query the latest stable release (not a draft or prerelease) with:

   ```sh
   gh api repos/golangci/golangci-lint/releases/latest --jq '{tag_name,html_url,published_at,draft,prerelease}'
   ```

2. Read the release notes for every stable release between the current and target versions. Do not look only for new top-level linters: upgrades can add analyzers to already-enabled aggregate linters such as `govet` or `staticcheck`.

3. Compare the official linter inventories at the two tags. This avoids depending on locally installed binaries:

   ```sh
   comm -13 \
     <(gh api 'repos/golangci/golangci-lint/contents/docs/data/linters_info.json?ref=vOLD' --jq .content | base64 --decode | jq -r '.[].name' | sort) \
     <(gh api 'repos/golangci/golangci-lint/contents/docs/data/linters_info.json?ref=vNEW' --jq .content | base64 --decode | jq -r '.[].name' | sort)
   ```

   Inspect each new entry's complete JSON object too, especially `since`, `isSlow`, `deprecation`, `replacement`, and `originalURL`. A renamed major-version replacement is not a genuinely new check.

4. Evaluate genuinely new checks for correctness value, applicability across all consumers, false-positive risk, speed, required configuration, and maintenance cost. Keep dependency-specific or highly opinionated checks out of the shared base; downstream repositories can enable them with `.golangci.patch`. Record the decision and rationale in the pull request.

5. Change the version comment on line 1, preserving its exact `# vX.Y.Z` format. If adopting a new linter, add its configuration explicitly and consider whether downstream `.golangci.patch` files still apply.

6. Validate with the exact target golangci-lint version:

   ```sh
   golangci-lint config verify --config .golangci.yml
   golangci-lint run --config .golangci.yml ./...
   go test ./...
   git diff --check
   ```

   When the ruleset body changes, also apply representative downstream `.golangci.patch` files with `git apply --check` against the updated base. The `self-test.yml` workflow must pass because it exercises the in-tree action; `all.yml` alone tests the action already on `main`.

## Gotchas

- Go caching is disabled in all CI jobs (`cache: false`) to prevent cache-poisoning. Local builds will always be faster than CI.
- Go tip failures are expected and do not block merges.
- Upstream xk6 changes can break CI without any change in this repo. If CI breaks after a green local build, check that upstream first.
- Line 1 of `.golangci.yml` is the golangci-lint version pin (`# vX.Y.Z`). Tooling reads it; do not remove the comment.
- The test file is intentionally named `mudule_test.go`. Do not rename it.
- The workflow's `skip-extension-testing` input is compared with `!= true` (not `!= 'true'`). GitHub coerces booleans for `workflow_dispatch` but not always for `workflow_call`; callers must pass a real boolean.
- **Self-CI gap on action changes**: `all.yml` references `.github/actions/{deps,lint}` as `grafana/k6-ci/...@main`, not `./`, because `./` resolves to the caller's workspace under workflow_call. Consequence: a PR to k6-ci that modifies one of those actions runs all.yml against the *merged* version of the action, not the PR's. The companion workflow `self-test.yml` uses `./` paths on push/PR to k6-ci and exercises the PR's version. Both should pass before merging an action change.
