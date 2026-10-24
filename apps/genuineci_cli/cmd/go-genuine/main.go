package main

import (
	"io"
	"os"
	"runtime/debug"

	"github.com/openci-org/openci/apps/genuineci_cli/internal/cli"
)

// Release builds can override version with -ldflags "-X main.version=v0.1.0".
var version string

func main() {
	os.Exit(run(os.Args[1:], buildVersion(), os.Stdout, os.Stderr))
}

func run(args []string, version string, stdout, stderr io.Writer) int {
	root := cli.NewRootCommand(version, stdout, stderr)
	root.SetArgs(args)
	if err := root.Execute(); err != nil {
		return 1
	}
	return 0
}

func buildVersion() string {
	if version != "" {
		return version
	}
	if info, ok := debug.ReadBuildInfo(); ok && info.Main.Version != "" && info.Main.Version != "(devel)" {
		return info.Main.Version
	}
	return "dev"
}
