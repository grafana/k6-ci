# k6-ci

Re-usable CI workflows for k6 and k6 extension development.

## Quick start (k6 extension)

1. Copy [`templates/k6-ci.yml`](templates/k6-ci.yml) to `.github/workflows/k6-ci.yml` and pin `@main` to a SHA. This calls the reusable workflow which runs:
   - `go mod tidy && go mod verify` dependency check
   - golangci-lint (canonical config + optional `.golangci.patch`)
   - tests on the current, previous, and tip Go versions × ubuntu/windows/macOS
   - xk6 build check
2. Copy [`templates/Makefile`](templates/Makefile), or integrate its equivalent
   targets into the repository's existing local tooling. Repositories adopting
   k6-ci are expected to provide this local path for running the same pinned
   lint configuration. When integrating into an existing Makefile and the
   repository has no `.golangci.patch`, keep the integration minimal: don't add
   patch application or patch-generation targets in anticipation of a patch.

Exceptions should be deliberate and documented in the adopting pull request.
For example, a repository may already provide equivalent commands through
another task runner, or may intentionally not support local Go development.

If your repo isn't an xk6 extension (library, k6 itself, etc.), flip `skip-extension-testing: true` in your copy of `k6-ci.yml`.

The pinned `@<ref>` drives everything: CI config, golangci-lint version, and (via the Makefile's grep) local lint.

The current and previous Go versions are defined once in
`.github/go-versions.env` and exposed to workflows by the `go-versions`
composite action.

## Shared golangci-lint config

`.golangci.yml` here is the canonical config. Line 1 (`# vX.Y.Z`) pins the golangci-lint version; everything below is the ruleset. The `all.yml` reusable workflow's `lint` job downloads it from this repo at the ref passed via the `k6-ci-ref` input (defaults to `main`). For reproducible CI, pin it to the same SHA as the `uses:` line.

### Project-specific tweaks

`.golangci.patch` is optional and should be a last resort. Prefer fixing the
code, or changing the shared configuration here when the rule is unsuitable for
all consumers. Add a patch only for a repository-specific constraint where
changing the code or the shared base would be inappropriate. No patch file →
base runs as-is.

When a patch is necessary, add it at the repository root as a unified diff
against `.golangci.yml`. The workflow applies it before linting.

Workflow for editing the patch:

```sh
make lint                # materializes .golangci.yml at the repo root (effective config)
$EDITOR .golangci.yml
make update-lint-patch   # rewrites .golangci.patch from the edits
```

Both `.golangci-base.yml` (cached download) and `.golangci.yml` (assembled) should be gitignored.

Constraints:

- Don't add an empty or preemptive patch.
- Don't edit line 1 of the base in your patch; bump the linter version here in k6-ci.
- If the base shifts and your patch no longer applies, the lint job fails — regenerate and commit.

## Makefile reference

The template is the default local tooling for repositories using k6-ci. It may
be integrated into an existing Makefile instead of copied verbatim, as long as
the resulting lint command uses the caller workflow's pinned k6-ci ref and runs
the pinned golangci-lint version with the canonical config. If the repository
has a `.golangci.patch`, local tooling must also assemble the canonical config
plus that patch. Don't expand an existing Makefile with patch-specific plumbing
when no patch exists. Repositories without a local equivalent should document
why they are an exception.

`templates/Makefile` targets:

| Target | Effect |
|---|---|
| `lint` | Download base, apply patch, run golangci-lint at the pinned version. |
| `update-lint-patch` | Regenerate `.golangci.patch` from the locally edited `$(LINT_FINAL)`. |
| `clean-lint` | Remove `$(LINT_BASE)` and `$(LINT_FINAL)`. |

Override variables on the command line (or in your top-level Makefile):

- `WORKFLOW` — file to read the k6-ci ref from. Default `.github/workflows/k6-ci.yml`.
- `LINT_BASE` — cached download path. Default `.golangci-base.yml`.
- `LINT_FINAL` — assembled config path. Default `.golangci.yml`.
- `LINT_PATCH` — patch file path. Default `.golangci.patch`.
