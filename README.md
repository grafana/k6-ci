# k6-ci

Re-usable CI workflows and GitHub Actions for k6 and k6 extension development.

## Quick start (k6 extension)

1. Copy [`templates/k6-ci.yml`](templates/k6-ci.yml) to `.github/workflows/k6-ci.yml` and pin `@main` to a SHA. This calls the reusable workflow which runs:
   - `go mod tidy && go mod verify` dependency check
   - golangci-lint (canonical config + optional `.golangci.patch`)
   - tests on Go 1.25/1.26/tip × ubuntu/windows
   - xk6 build check
2. Optionally copy [`templates/Makefile`](templates/Makefile) for `make lint` locally.

If your repo isn't an xk6 extension (library, k6 itself, etc.), flip `skip-extension-testing: true` in your copy of `k6-ci.yml`.

The pinned `@<ref>` drives everything: CI config, golangci-lint version, and (via the Makefile's grep) local lint.

## Shared golangci-lint config

`.golangci.yml` here is the canonical config. Line 1 (`# vX.Y.Z`) pins the golangci-lint version; everything below is the ruleset. The action downloads it from this repo at the caller's pinned ref.

### Project-specific tweaks

Drop a `.golangci.patch` at your repo root — a unified diff against `.golangci.yml`. The action applies it before linting. No patch file → base runs as-is.

Workflow for editing the patch:

```sh
make lint                # materializes build/lint/.golangci.yml (the effective config)
$EDITOR build/lint/.golangci.yml
make update-lint-patch   # rewrites .golangci.patch from the edits
```

Constraints:

- Don't edit line 1 of the base in your patch; bump the linter version here in k6-ci.
- If the base shifts and your patch no longer applies, the lint job fails — regenerate and commit.

## Makefile reference

`templates/Makefile` targets:

| Target | Effect |
|---|---|
| `lint` | Download base, apply patch, run golangci-lint at the pinned version. |
| `update-lint-patch` | Regenerate `.golangci.patch` from the locally edited `$(LINT_FINAL)`. |
| `clean-lint` | Remove `$(LINT_DIR)`. |

Override variables on the command line (or in your top-level Makefile):

- `WORKFLOW` — file to read the k6-ci ref from. Default `.github/workflows/k6-ci.yml`.
- `LINT_DIR` — where the assembled config lives. Default `build/lint`.
- `LINT_PATCH` — patch file path. Default `.golangci.patch`.
