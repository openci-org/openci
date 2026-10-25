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

## Personal settings paths

Personal settings currently target macOS and Linux.

`internal/config.ResolvePaths()` locates `config.json` and `credentials.json`
under `xdg.ConfigHome/genuineci`, using
[`adrg/xdg`](https://github.com/adrg/xdg). An absolute `XDG_CONFIG_HOME` overrides
the default on every supported OS. Otherwise, typical locations are:

| OS | Directory |
| --- | --- |
| macOS | `$HOME/Library/Application Support/genuineci` |
| Linux | `$HOME/.config/genuineci` |

The resolver only returns paths and reports an error if XDG has no config home.
It does not create or modify files or directories. XDG determines its paths at
process startup; empty or invalid XDG variables use the library's defaults.

The Go CLI starts with fresh settings. Dart CLI files under `openci` are not
imported or migrated.

## Language settings

`internal/config.NewStore()` resolves the personal `config.json` path and creates
an independent [Viper](https://github.com/spf13/viper) instance. `store.Load()`
returns typed `Settings`, and `store.SetLanguage("ja")` or
`store.SetLanguage("en")` saves the selected language through `WriteFile` with
mode `0600`.

```json
{
  "language": "ja"
}
```

A missing file, omitted `language`, or `"language": null` uses English (`en`).
Reading never creates files or directories or writes these defaults to disk.
Empty files, malformed JSON, non-object roots, language values other than a
string or null, and strings other than `ja` or `en` return errors. Explicit
updates accept only `ja` and `en`. Invalid or unreadable existing files are left
intact when an update is attempted.

Each load rereads the file. Language updates load the current settings before
saving Viper's normalized settings.
Keys follow Viper's case-insensitive behavior; language values are case-sensitive.
Credentials remain in their separate file. The `use japanese/english` commands
and translated output will be added later; help, version, and completion do not
load settings.

## Saving settings files

`internal/config.WriteFile(path, data, mode)` saves already-encoded bytes. It
creates missing parent directories with mode `0700`, then creates a unique
temporary file alongside the destination. It applies the requested file mode
before writing, syncs and closes the file, and replaces the destination only
after those steps succeed. Credential callers should pass `0600`; replacing an
existing file also applies this mode on macOS/Linux.

Failures before replacement leave the previous file unchanged and remove the
temporary file. Cleanup errors are returned alongside the original error, without
including the payload. The helper does not parse JSON or resolve config paths.

Replacement uses [`os.Rename`](https://pkg.go.dev/os#Rename). This
helper does not lock concurrent saves or guarantee recovery after a power loss.

## Layout and checks

```text
cmd/go-genuine/    Entry point, exit codes, version discovery, and command tests
internal/cli/     Cobra command tree
internal/config/  Personal settings paths, safe file writes, and language settings
```

Add migrated commands to the command tree, with domain logic in focused
`internal` packages. Credential persistence and interactive forms can be
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
