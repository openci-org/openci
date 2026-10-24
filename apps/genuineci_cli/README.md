# GenuineCI CLI (Go)

The Go CLI is developed alongside `apps/openci_cli` and runs as `go-genuine`.
The initial commands are help, version, and shell completion. Authentication,
teams, secrets, workflow generation, and local development are future migration
steps. This base does not read or write the Dart CLI's settings or credentials.

## Run from source

Use Go 1.27 or later. From the repository root:

```sh
cd apps/genuineci_cli
go run ./cmd/go-genuine --help
go run ./cmd/go-genuine --version
```

To build a standalone executable:

```sh
go build -o build/go-genuine ./cmd/go-genuine
./build/go-genuine --help
```

The executable does not require Go or Dart to run.

## Install locally

From `apps/genuineci_cli`:

```sh
go install ./cmd/go-genuine
go-genuine --help
```

Go installs into `GOBIN`, or into `$(go env GOPATH)/bin` when `GOBIN` is unset.
Ensure that directory is on `PATH`. On macOS/Linux, an alternative is:

```sh
mkdir -p "$HOME/.local/bin"
GOBIN="$HOME/.local/bin" go install ./cmd/go-genuine
```

Use this alternative when `$HOME/.local/bin` is on `PATH`.
The existing `genuineci` command continues to run the Dart CLI.

## Commands

```sh
go-genuine --help
go-genuine version
go-genuine --version
go-genuine completion bash
go-genuine completion zsh
go-genuine completion fish
go-genuine completion powershell
```

Completion commands print scripts to stdout; they do not modify shell startup
files. Run `go-genuine completion <shell> --help` for installation instructions.
Commands return 0 on success and 1 when Cobra returns an error. Errors are written
to stderr. Help and completion use Cobra's standard behavior, including help
responses with exit code 0 for unknown help topics or shells.

Local builds report `dev`. Versioned `go install` builds use Go's embedded module
version. Release builds can set an explicit version:

```sh
go build -ldflags '-X main.version=v0.1.0' -o build/go-genuine ./cmd/go-genuine
```

## Layout and checks

```text
cmd/go-genuine/    Entry point, exit codes, version discovery, and command tests
internal/cli/     Cobra command tree
```

Add migrated commands to the command tree, with domain logic in focused
`internal` packages. Configuration, credentials, and interactive forms can be
introduced with the commands that need them.

Run from this module:

```sh
gofmt -w cmd internal
go vet ./...
go test -race ./...
go build ./cmd/go-genuine
```

The repository workflow is `openci/genuineci_cli_ci.dart`.

## Distribution plan

Public distribution has not been configured or published yet. Start with
`go install` for Go developers. Because this is a nested module, use tags such as
`apps/genuineci_cli/v0.1.0`, following the
[Go module version rules](https://go.dev/ref/mod#vcs-version).

After that example tag is published, installation will be:

```sh
go install github.com/openci-org/openci/apps/genuineci_cli/cmd/go-genuine@v0.1.0
```

GitHub Releases archives with SHA-256 checksums and an organization-owned
Homebrew tap can be added later for users without Go installed. GoReleaser can
build and package those binaries.

Keep CLI release selection separate from the monorepo's other applications.
