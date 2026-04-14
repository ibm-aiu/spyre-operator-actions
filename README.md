# Spyre Operator GitHub Actions

Reusable GitHub Actions workflows for spyre-operator CI/CD pipeline.

## Available Workflows

| Workflow | Description | Use Case |
|----------|-------------|----------|
| [pre-commit.yaml](.github/workflows/pre-commit.yaml) | Run pre-commit hooks | PR checks, code quality |
| [unit-test.yaml](.github/workflows/unit-test.yaml) | Run Go unit tests and build | PR checks, continuous testing |
| [version-patch.yaml](.github/workflows/version-patch.yaml) | Create a PR to bump the VERSION file | Manual version updates |
| [create-release.yaml](.github/workflows/create-release.yaml) | Create GitHub release from VERSION file | Release automation |
| [sync-issues-to-projects.yaml](.github/workflows/sync-issues-to-projects.yaml) | Sync issue lifecycle events to multiple GitHub Projects v2 boards | Issue tracking across torch-spyre and ibm-aiu org projects |

## Workflow Inputs Reference

### Pre-commit Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/pre-commit.yaml@main
with:
  python-version: '3.13'              # Python version (default: '3.13')
  goprivate: 'github.com/ibm-aiu'    # GOPRIVATE for private modules (optional)
secrets:
  gh-token: ${{ secrets.GH_PAT }}    # PAT with repo scope (required for private repos)
```

**Inputs:**

- `python-version` (optional): Python version to use for pre-commit hooks
  - Type: string
  - Default: `'3.13'`
- `goprivate` (optional): GOPRIVATE environment variable for private Go modules
  - Type: string
  - Default: `''`
  - Example: `'github.com/ibm-aiu'` or `'github.com/ibm-aiu/*'`

**Secrets:**

- `gh-token` (optional): GitHub Personal Access Token with `repo` scope
  - Required if your code depends on private Go modules
  - Falls back to `GITHUB_TOKEN` if not provided (limited access)
  - Create PAT at: Settings → Developer settings → Personal access tokens

### Unit Test Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/unit-test.yaml@main
with:
  go-version: '1.24.13'              # Go version (default: '1.24.13')
  goprivate: 'github.com/ibm-aiu'    # GOPRIVATE for private modules (optional)
secrets:
  gh-token: ${{ secrets.GH_PAT }}    # PAT with repo scope (required for private repos)
```

**Inputs:**

- `go-version` (optional): Go version to use for tests and build
  - Type: string
  - Default: `'1.24.13'`
- `goprivate` (optional): GOPRIVATE environment variable for private Go modules
  - Type: string
  - Default: `''`
  - Example: `'github.com/ibm-aiu'` or `'github.com/ibm-aiu/*'`

**Secrets:**

- `gh-token` (optional): GitHub Personal Access Token with `repo` scope
  - Required if your code depends on private Go modules
  - Falls back to `GITHUB_TOKEN` if not provided (limited access)
  - Create PAT at: Settings → Developer settings → Personal access tokens

### Version Patch Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/version-patch.yaml@main
with:
  version_bump: ${{ inputs.version_bump }}  # Required: minor or major
  operator_sdk_version: 'v1.38.0'           # Optional: operator-sdk version (default: 'v1.38.0')
```

**Inputs:**

- `version_bump` (required): Version bump type
  - Type: choice
  - Options: `minor`, `major`
- `operator_sdk_version` (optional): Operator SDK version to install
  - Type: string
  - Default: `'v1.38.0'`
  - Only used for spyre-operator projects

**Permissions:**

- `contents: write`: Required to create the version bump branch and commit changes
- `pull-requests: write`: Required to create the pull request
- `actions: read`: Required for private reusable workflows

**Requirements:**

- Repository must contain a `VERSION` file
- Default target branch is `main`

**Special Behavior for spyre-operator Projects:**

When the workflow detects that the repository name is `spyre-operator`, it automatically performs additional steps after incrementing the version:

1. **Retrieve component versions**: Fetches the latest VERSION from dependent components:
   - spyre-device-plugin
   - spyre-scheduler
   - spyre-webhook-validator
   - spyre-health-checker
   - spyre-exporter
   - dra-driver-spyre
   
   All retrieved versions automatically get a `-dev` suffix appended. If a component's VERSION file is not found, it uses `$(cat VERSION)-dev` as a fallback version.

2. **Update release-artifacts.yaml**: Uses `yq` to update component versions in the release-artifacts.yaml file with the retrieved versions (or fallback versions) from step 1.

3. **Install operator-sdk**: Downloads and installs the specified version of operator-sdk

4. **Run make bundle**: Generates operator bundle manifests

5. **Run make propagate-version**: Propagates the new version throughout the project files

These steps ensure that all operator-related files and component dependencies are updated with the correct versions before creating the pull request.

### Create Release Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/create-release.yaml@main
with:
  draft: false                        # Create as draft (default: false)
  prerelease: false                   # Mark as prerelease (default: false)
  generate_release_notes: true        # Auto-generate notes (default: true)
  tag_prefix: 'v'                     # Tag prefix (default: 'v')
secrets:
  gh-token: ${{ secrets.GITHUB_TOKEN }}  # GitHub token (optional)
```

**Inputs:**

- `draft` (optional): Create release as draft
  - Type: boolean
  - Default: `false`
  - When `true`, release is created but not published
- `prerelease` (optional): Mark release as prerelease
  - Type: boolean
  - Default: `false`
  - Useful for beta/RC versions
- `generate_release_notes` (optional): Automatically generate release notes
  - Type: boolean
  - Default: `true`
  - GitHub will generate notes from commits and PRs
- `tag_prefix` (optional): Prefix for the git tag
  - Type: string
  - Default: `'v'`
  - Example: `'v'` creates tags like `v1.0.0`, empty string creates `1.0.0`

**Secrets:**

- `gh-token` (optional): GitHub token for creating releases
  - Falls back to `GITHUB_TOKEN` if not provided
  - `GITHUB_TOKEN` is usually sufficient for public repositories

**Permissions:**

- `contents: write`: Required to create tags and releases
- `actions: read`: Required for private reusable workflows

**Requirements:**

- Repository must contain a `VERSION` file with semantic version (e.g., `1.0.0`)
- The workflow checks if the tag already exists to avoid conflicts

### Sync Issues to Projects Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/sync-issues-to-projects.yaml@main
secrets:
  project-token: ${{ secrets.TORCH_SPYRE_PROJECT_TOKEN }}
```

**Inputs (all optional):**

- `status-field-name`: Name of the single-select status field in both project boards
  - Type: string
  - Default: `'Status'`
- `status-triage`: Option label applied when an issue is opened or reopened
  - Type: string
  - Default: `'Triage'`
- `status-done`: Option label applied when an issue is closed
  - Type: string
  - Default: `'Done'`

**Secrets:**

- `project-token` (required): PAT with Projects read & write access on both `torch-spyre` and `ibm-aiu` orgs
  - Classic PAT scope: `project`

**What it does:**

- On `opened` / `reopened`: adds the issue to both org project boards (idempotent) and sets status to `Triage`
- On `closed`: finds the existing project item in both boards and sets status to `Done`
- Both org projects (`torch-spyre/projects/2` and `ibm-aiu/projects/1`) are updated in parallel

**Example caller workflow** (place in `ibm-aiu/spyre-operator/.github/workflows/sync-issues-to-projects.yaml`):

```yaml
name: Sync Issues to Projects

on:
  issues:
    types: [opened, closed, reopened]

jobs:
  sync:
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/sync-issues-to-projects.yaml@main
    secrets:
      project-token: ${{ secrets.TORCH_SPYRE_PROJECT_TOKEN }}
```

## Advanced Usage

### Using Different Versions

Override default versions:

```yaml
unit-test:
  uses: ibm-aiu/spyre-operator-actions/.github/workflows/unit-test.yaml@main
  with:
    go-version: '1.23.0'  # Use different Go version
```

### Pinning to Specific Version

Instead of using `@main`, pin to a specific version:

```yaml
pre-commit:
  uses: ibm-aiu/spyre-operator-actions/.github/workflows/pre-commit.yaml@v1.0.0
```

### Sequential Job Execution

Use `needs` to control job execution order:

```yaml
jobs:
  pre-commit:
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/pre-commit.yaml@main
  
  unit-test:
    needs: pre-commit  # Only runs if pre-commit succeeds
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/unit-test.yaml@main
```

## Requirements

### Workflow-Specific Requirements

**Pre-commit and Unit Test:**
- Repository must have `make test` and `make build` targets

**Create Release:**
- Repository must have a `VERSION` file containing semantic version (e.g., `1.0.0`)
- The `VERSION` file should be updated before triggering the release workflow

## License

Apache-2.0

## Support

For issues or questions:

- Open an issue in the spyre-operator-actions repository
- Check existing issues for similar problems
- Provide workflow run logs when reporting issues
