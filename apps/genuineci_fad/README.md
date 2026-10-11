# genuineci-fad

Go command-line tool for Firebase App Distribution, intended to run on the
build machine alongside the IPA produced by the workflow.

The CLI provides generated help and an `upload` command with two required flags:
`--ipa` and `--app-id`. Upload support is not implemented yet.

## Requirements

- Go 1.27.2 or later to build from source.

This is an independent Go module using [urfave/cli v3](https://cli.urfave.org/v3/getting-started/)
for argument parsing and help generation. Run the commands below from
`apps/genuineci_fad/`.

## Run

```sh
go run ./cmd/genuineci-fad --help
go run ./cmd/genuineci-fad help
go run ./cmd/genuineci-fad upload --help
```

Pass the IPA path and Firebase App ID explicitly:

```sh
go run ./cmd/genuineci-fad upload \
  --ipa build/ios/ipa/app.ipa \
  --app-id 1:123456789:ios:abcdef
```

Missing required flags cause an error. With both flags supplied, the command
currently exits with `upload is not implemented yet` and a non-zero status.

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
root and upload help, missing required flags, and the unimplemented upload error.
Unsupported commands and flags should also exit with a non-zero status.
