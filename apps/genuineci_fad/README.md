# genuineci-fad

Go command-line tool for Firebase App Distribution, intended to run on the
build machine alongside the IPA produced by the workflow.

This initial module provides an executable entry point and generated help output.
Upload support is not implemented yet; unsupported commands and flags exit
with a non-zero status.

## Requirements

- Go 1.27.2 or later to build from source.

This is an independent Go module using [urfave/cli v3](https://cli.urfave.org/v3/getting-started/)
for argument parsing and help generation. Run the commands below from
`apps/genuineci_fad/`.

## Run

```sh
go run ./cmd/genuineci-fad --help
go run ./cmd/genuineci-fad help
```

## Build

```sh
go build -o build/genuineci-fad ./cmd/genuineci-fad
./build/genuineci-fad --help
```

The compiled binary can run without a Go installation. The repository's root
`.gitignore` excludes the `build/` directory.

## Check

```sh
go fmt ./...
go vet ./...
go test ./...
```

There are no Go test files in this initial scaffold. Check the compiled binary's
help output and verify that an unsupported command or flag exits with a non-zero
status.
