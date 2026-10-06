# Spyre Operator GitHub Actions

Reusable GitHub Actions workflows for spyre-operator CI/CD pipeline.

## Available Workflows

| Workflow | Description | Use Case |
| --- | --- | --- |
| [pre-commit.yaml](.github/workflows/pre-commit.yaml) | Run pre-commit hooks and Go module vendoring | PR checks, code quality |
| [unit-test.yaml](.github/workflows/unit-test.yaml) | Run Go unit tests and build | PR checks, continuous testing |
| [build-image.yaml](.github/workflows/build-image.yaml) | Build multi-arch container images (amd64, ppc64le, s390x) and push manifest | Image builds and releases |
| [crc-e2e-test.yaml](.github/workflows/crc-e2e-test.yaml) | Run OpenShift Local (CRC) end-to-end tests | End-to-end testing, PR validation |
| [version-patch.yaml](.github/workflows/version-patch.yaml) | Create a PR to bump the VERSION file | Version updates |
| [version-patch-actions.yaml](.github/workflows/version-patch-actions.yaml) | Bump VERSION and update E2E resolution defaults for spyre-operator-actions | Workflow repo version updates |
| [create-release.yaml](.github/workflows/create-release.yaml) | Create GitHub tag and release from VERSION file | Release automation |
| [sonarqube-scan.yaml](.github/workflows/sonarqube-scan.yaml) | Perform SonarQube code quality and coverage analysis | Code quality |
| [auto-label-pr.yaml](.github/workflows/auto-label-pr.yaml) | Automatically label PRs based on title prefix | PR automation |

## Workflow Inputs Reference

- [Pre-commit Workflow](#pre-commit-workflow)
- [Unit Test Workflow](#unit-test-workflow)
- [Build Image Workflow](#build-image-workflow)
- [CRC End-to-End Test Workflow](#crc-end-to-end-test-workflow)
- [Version Patch Workflow](#version-patch-workflow)
- [Version Patch Workflow (Actions Repository)](#version-patch-workflow-actions-repository)
- [Create Release Workflow](#create-release-workflow)
- [SonarQube Scan Workflow](#sonarqube-scan-workflow)
- [Auto Label PR Workflow](#auto-label-pr-workflow)

---

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
  - Falls back to `GITHUB_TOKEN` if not provided

**Permissions:**

- `read-all`

---

### Unit Test Workflow

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/unit-test.yaml@main
with:
  go-version: ''                     # Go version (leave empty to read from go.mod)
  goprivate: 'github.com/ibm-aiu'    # GOPRIVATE for private modules (optional)
secrets:
  gh-token: ${{ secrets.GH_PAT }}    # PAT with repo scope (required for private repos)
```

**Inputs:**

- `go-version` (optional): Go version to use for tests and build
  - Type: string
  - Default: `''` (reads Go version from `go.mod` if empty)
  - Example: `'1.24.0'`
- `goprivate` (optional): GOPRIVATE environment variable for private Go modules
  - Type: string
  - Default: `''`
  - Example: `'github.com/ibm-aiu'` or `'github.com/ibm-aiu/*'`

**Secrets:**

- `gh-token` (optional): GitHub Personal Access Token with `repo` scope
  - Required if your code depends on private Go modules
  - Falls back to `GITHUB_TOKEN` if not provided

**Permissions:**

- `read-all`

---

### Build Image Workflow

Builds multi-architecture container images across `amd64`, `ppc64le`, and `s390x` platforms and pushes a multi-arch manifest.

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/build-image.yaml@main
with:
  image_name: 'spyre-operator'        # Name of the container image
  runner: 'ubuntu-latest'             # GitHub runner for amd64, metadata, and manifest jobs (default: 'ubuntu-latest')
  dockerfile: './Dockerfile'          # Path to Dockerfile (default: './Dockerfile')
  image_suffix: '-dev'                # Image tag suffix (default: '-dev')
  registry: 'ghcr.io/ibm-aiu'         # Container registry (default: 'ghcr.io/ibm-aiu')
  pre_build_command: ''               # Optional command to run before docker build (default: '')
  push: true                          # Push image and manifest to registry (default: true)
# No secrets needed for pushing to ghcr.io in the same org - uses GITHUB_TOKEN automatically
```

For custom registries (Docker Hub, Quay.io, etc.):

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/build-image.yaml@main
with:
  image_name: 'your-image-name'
  registry: 'your-registry'
secrets:
  registry-username: ${{ secrets.DOCKER_USERNAME }}
  registry-password: ${{ secrets.DOCKER_PASSWORD }}
```

**Inputs:**

- `image_name` (optional): Name of the container image (e.g., `'spyre-operator'`)
  - Type: string
  - Default: `''`
- `runner` (optional): GitHub runner to use for metadata, manifest creation, and the amd64 build
  - Type: string
  - Default: `'ubuntu-latest'`
- `dockerfile` (optional): Path to Dockerfile
  - Type: string
  - Default: `'./Dockerfile'`
- `image_suffix` (optional): Suffix to append to IMAGE_TAG
  - Type: string
  - Default: `'-dev'`
  - Example: `'-dev'` creates tags like `1.0.0-dev`
- `registry` (optional): Container registry to push to
  - Type: string
  - Default: `'ghcr.io/ibm-aiu'`
  - Examples: `'ghcr.io/ibm-aiu'`, `'docker.io/user'`, `'quay.io/org'`
- `pre_build_command` (optional): Command to run before `docker build` (e.g., code generation or binary compilation)
  - Type: string
  - Default: `''`
- `push` (optional): Whether to push images and the multi-arch manifest to the registry
  - Type: boolean
  - Default: `true`

**Secrets:**

- `registry-username` (optional): Container registry username
  - **Not needed for ghcr.io** — uses `github.actor` automatically
  - Required for external registries (Docker Hub, Quay.io, etc.)
- `registry-password` (optional): Container registry password or token
  - **Not needed for ghcr.io** — uses `GITHUB_TOKEN` automatically
  - Required for external registries (Docker Hub, Quay.io, etc.)

**Permissions:**

- `contents: read`
- `packages: write` (required for pushing images and manifests to `ghcr.io`)

**Architecture Matrix:**

The workflow builds images across three architectures and combines them into a multi-arch manifest:

- **`amd64`** (`linux/amd64`): Runs on `${{ inputs.runner }}`
- **`ppc64le`** (`linux/ppc64le`): Runs on `ubuntu-24.04-ppc64le-p10`
- **`s390x`** (`linux/s390x`): Runs on `[self-hosted, Linux, S390X]`

**How it works:**

1. **Metadata Job**: Reads the version from the `VERSION` file and constructs the `IMAGE_TAG` (appends `image_suffix` if not already present).
2. **Build Image Job**: Builds and pushes architecture-tagged images (`<registry>/<image_name>:<tag>-<arch>`) for each platform in the matrix.
3. **Manifest Job**: Uses `docker buildx imagetools create` to assemble and push a multi-architecture manifest at `<registry>/<image_name>:<tag>`.

---

### CRC End-to-End Test Workflow

Runs end-to-end tests for the Spyre operator on an OpenShift Local (CRC) cluster. Supports testing pull request branches from component repositories.

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/crc-e2e-test.yaml@main
with:
  runner: 'ubuntu-24.04'                      # Runner for CRC test (default: 'ubuntu-24.04')
  repository: 'ibm-aiu/spyre-operator'       # Target repository (default: 'ibm-aiu/spyre-operator')
  branch-name: 'main'                        # Branch to checkout (default: 'main')
  pr-url: ''                                 # Optional: PR URL for testing component PR changes
  crc-version: '2.61.0'                      # CRC version (default: '2.61.0', OpenShift 4.21)
  registry: 'ghcr.io/ibm-aiu'                # Container registry (default: 'ghcr.io/ibm-aiu')
secrets:
  crc-pull-secret: ${{ secrets.CRC_PULL_SECRET }}  # Required: Red Hat / CRC pull secret
  github-token: ${{ secrets.GITHUB_TOKEN }}        # Required: GitHub token for repo and registry access
```

**Inputs:**

- `runner` (optional): GitHub runner for the test environment
  - Type: string
  - Default: `'ubuntu-24.04'`
- `branch-name` (optional): Branch name to checkout from the repository
  - Type: string
  - Default: `'main'`
- `registry` (optional): Container registry to pull base images from
  - Type: string
  - Default: `'ghcr.io/ibm-aiu'`
- `pr-url` (optional): GitHub Pull Request URL to test. When provided, the workflow fetches the PR branch, builds its container image, and pushes it directly into the CRC internal registry.
  - Type: string
  - Default: `''`
- `operator-version` (optional): Spyre operator version tag to test
  - Type: string
  - Default: `''` (resolved automatically from `resolve-e2e-params`)
- `operator-channel` (optional): Operator channel (e.g., `fast-v1.5`)
  - Type: string
  - Default: `''` (resolved automatically from `resolve-e2e-params`)
- `repository` (optional): Target repository to clone for E2E tests
  - Type: string
  - Default: `'ibm-aiu/spyre-operator'`
- `path` (optional): Directory path where the repository is cloned
  - Type: string
  - Default: `'spyre-operator'`
- `actions-ref` (optional): Branch or ref to checkout from `spyre-operator-actions`
  - Type: string
  - Default: `'main'`
- `crc-version` (optional): OpenShift Local (CRC) version
  - Type: string
  - Default: `'2.61.0'` (OpenShift 4.21)

**Secrets:**

- `crc-pull-secret` (required): CRC pull secret for provisioning OpenShift Local
- `github-token` (required): GitHub token for repository access and registry authentication

**Permissions:**

- `read-all`

**Workflow Steps:**

1. Check out `spyre-operator-actions` and resolve E2E execution parameters.
2. Install `operator-sdk` (v1.38.0) and `stern` (v1.30.0).
3. Check out the target operator repository.
4. If `pr-url` is supplied, clone the PR branch and build its container image locally.
5. Apply E2E configuration patches.
6. Provision OpenShift Local via `crc-org/crc-github-action` (16 vCPUs, 15.2 GB RAM, 128 GB disk).
7. Authenticate to the CRC cluster, update the global pull secret, and push test images to the CRC registry.
8. Apply the Spyre device plugin SELinux `MachineConfig` and restart the CRC cluster.
9. Start background log capture across Spyre components.
10. Run `make e2e-test`.
11. Collect diagnostic dumps and upload component logs as workflow artifacts.

---

### Version Patch Workflow

Reusable workflow to increment the `VERSION` file and open a version bump pull request.

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/version-patch.yaml@main
with:
  version_bump: 'minor'               # Required: minor or major
```

**Inputs:**

- `version_bump` (required): Version bump type
  - Type: string
  - Default: `'minor'`
  - Options: `'minor'`, `'major'`

**Outputs:**

- `branch_name`: Name of the created version bump branch (e.g., `version-patch/v1.5.0`)
- `new_version`: The incremented version number (e.g., `1.5.0`)

**Permissions:**

- `contents: write`: Required to create the version bump branch and commit changes
- `pull-requests: write`: Required to create the pull request

**Requirements:**

- Repository must contain a `VERSION` file with a semantic version string (e.g., `1.4.0`)

---

### Version Patch Workflow (Actions Repository)

Workflow specifically designed for `spyre-operator-actions` repository version bumps. Triggered manually via `workflow_dispatch`.

```yaml
# Triggered via GitHub UI / CLI workflow_dispatch on spyre-operator-actions
gh workflow run version-patch-actions.yaml -f version_bump=minor
```

**Inputs:**

- `version_bump` (required): Bump type (`minor` or `major`, default: `'minor'`)

**How it works:**

1. Calls `version-patch.yaml` to increment the `VERSION` file and create a PR branch.
2. Runs the `update-resolve-e2e-params` job to update the default `OPERATOR_VERSION` and `OPERATOR_CHANNEL` values in `.github/actions/resolve-e2e-params/action.yaml`.
3. Commits and pushes the updated action file to the version bump PR branch.

---

### Create Release Workflow

Creates a Git tag and publishes a GitHub release based on the version in the `VERSION` file.

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
- `prerelease` (optional): Mark release as prerelease
  - Type: boolean
  - Default: `false`
- `generate_release_notes` (optional): Automatically generate release notes from commits and PRs
  - Type: boolean
  - Default: `true`
- `tag_prefix` (optional): Prefix for the git tag
  - Type: string
  - Default: `'v'`
  - Example: `'v'` creates tags like `v1.0.0`, empty string `''` creates `1.0.0`

**Secrets:**

- `gh-token` (optional): GitHub token for creating tags and releases (falls back to `GITHUB_TOKEN`)

**Permissions:**

- `contents: write`: Required to create tags and releases

**Requirements:**

- Repository must contain a `VERSION` file containing semantic version (e.g., `1.0.0`)

---

### SonarQube Scan Workflow

Performs SonarQube static analysis and code coverage reporting.

**Triggers:**

- `push`: Runs on pushes to the `main` branch
- `pull_request`: Runs on PR events (`opened`, `synchronize`, `reopened`)
- `workflow_dispatch`: Can be manually triggered

**Required Secrets:**

Secrets are typically defined at the organization level:

- `SONAR_TOKEN`: SonarQube authentication token
- `SONAR_HOST_URL`: URL of the SonarQube server
- `SONAR_TRUSTSTORE_BASE64`: Base64-encoded truststore file for SSL/TLS verification
- `SONAR_CERTS_PASSWORD`: Password for the truststore file
- `ORGID`: Organization identifier used in the project key

**How it works:**

1. Checks out the repository.
2. If `go.mod` is present, sets up Go using the version specified in `go.mod`.
3. If `Makefile` has a `test:` target, executes `make test` to generate test coverage (`coverage.out`).
4. Reconstructs and verifies the SSL truststore certificate.
5. Runs `sonarsource/sonarqube-scan-action` configured with project key `${ORGID}-${repository_id}`, coverage file `coverage.out`, and branch/PR metadata.

---

### Auto Label PR Workflow

Automatically labels PRs based on conventional commit prefixes in the PR title.

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/auto-label-pr.yaml@main
# No inputs or secrets required - uses GITHUB_TOKEN automatically
```

**Triggers:**

- `pull_request`: Runs when PRs are `opened`, `synchronize`, `reopened`, or `edited`
- `workflow_call`: Can be called from other workflows

**Label Mapping:**

| PR Title Prefix | Label Applied | Description |
| --- | --- | --- |
| `feat:` | `enhancement` | New features or enhancements |
| `feat(major):` | `semver-major` | Breaking changes requiring major version bump |
| `fix:` | `bug` | Bug fixes |
| `ci:` or `chore:` | `chore` | CI/CD, tooling, and maintenance changes |

**Behavior:**

1. **Removes old auto-labels**: Before applying new labels, removes any previously auto-applied labels (`enhancement`, `semver-major`, `bug`, `chore`).
2. **Applies new label**: Adds label matching the current PR title prefix.
3. **Updates on title edit**: Automatically syncs labels when a PR title is modified.
4. **Preserves manual labels**: Only manages the 4 auto-applied labels; other labels are untouched.

**Permissions:**

- `pull-requests: write`: Required to add and remove labels
- `contents: read`: Required to inspect PR metadata

---

## Advanced Usage

### Sequential Job Execution

Use `needs` to chain workflows together:

```yaml
jobs:
  pre-commit:
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/pre-commit.yaml@main

  unit-test:
    needs: pre-commit  # Only runs if pre-commit succeeds
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/unit-test.yaml@main

  build-image:
    needs: unit-test
    permissions:
      packages: write
    uses: ibm-aiu/spyre-operator-actions/.github/workflows/build-image.yaml@main
    with:
      image_name: 'spyre-operator'
```

### Pinning to Specific Version

Instead of using `@main`, pin to a release tag or commit SHA for reproducible builds:

```yaml
uses: ibm-aiu/spyre-operator-actions/.github/workflows/pre-commit.yaml@v1.5.0
```

---

## Requirements

### Workflow Requirements Summary

| Workflow | Key Requirements |
| --- | --- |
| **Pre-commit** | Python available on runner, `go.mod` (if Go project), pre-commit configuration |
| **Unit Test** | `make test` and `make build` targets in `Makefile` |
| **Build Image** | `VERSION` file, `Dockerfile` at target path, `packages: write` permission |
| **CRC E2E Test** | `crc-pull-secret`, `github-token`, OpenShift Local compatible runner |
| **Version Patch** | `VERSION` file containing semantic version (e.g., `1.0.0`) |
| **Create Release** | `VERSION` file, `contents: write` permission |
| **SonarQube Scan** | SonarQube organization secrets, `make test` producing `coverage.out` |

## License

Apache-2.0

## Support

For issues or questions:

- Open an issue in the [spyre-operator-actions](https://github.com/ibm-aiu/spyre-operator-actions) repository
- Check existing issues for similar problems
- Provide workflow run logs when reporting issues
