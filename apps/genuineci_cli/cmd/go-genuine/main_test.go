package main

import (
	"bytes"
	"errors"
	"strings"
	"testing"
)

func TestRun(t *testing.T) {
	for _, test := range []struct {
		name   string
		args   []string
		code   int
		stdout string
		stderr string
	}{
		{name: "no command", args: []string{}, stdout: "Usage:"},
		{name: "help", args: []string{"--help"}, stdout: "go-genuine [command]"},
		{name: "command help", args: []string{"help", "version"}, stdout: "Print the CLI version"},
		{name: "completion help", args: []string{"completion"}, stdout: "Generate the autocompletion script"},
		{name: "version flag", args: []string{"--version"}, stdout: "go-genuine version v0.1.0-test\n"},
		{name: "short version flag", args: []string{"-v"}, stdout: "go-genuine version v0.1.0-test\n"},
		{name: "version command", args: []string{"version"}, stdout: "go-genuine version v0.1.0-test\n"},
		{name: "unknown command", args: []string{"login"}, code: 1, stderr: `unknown command "login"`},
		{name: "unknown flag", args: []string{"--unknown"}, code: 1, stderr: "unknown flag: --unknown"},
		{name: "invalid flag value", args: []string{"--version=invalid"}, code: 1, stderr: "invalid argument"},
		{name: "unexpected argument", args: []string{"version", "extra"}, code: 1, stderr: `unknown command "extra"`},
		{name: "unexpected completion argument", args: []string{"completion", "bash", "extra"}, code: 1, stderr: `unknown command "extra"`},
		{name: "unknown shell shows help", args: []string{"completion", "invalid"}, stdout: "go-genuine completion [command]"},
		{name: "unknown help topic", args: []string{"help", "invalid"}, stdout: "Unknown help topic"},
		{name: "extra help argument", args: []string{"help", "version", "extra"}, stdout: "Print the CLI version"},
	} {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			var stdout, stderr bytes.Buffer
			code := run(test.args, "v0.1.0-test", &stdout, &stderr)
			if code != test.code {
				t.Fatalf("exit code = %d, want %d; stderr: %s", code, test.code, &stderr)
			}
			if test.stdout == "" {
				if stdout.Len() != 0 {
					t.Errorf("unexpected stdout: %s", &stdout)
				}
			} else if !strings.Contains(stdout.String(), test.stdout) {
				t.Errorf("stdout = %q, want it to contain %q", stdout.String(), test.stdout)
			}
			if test.stderr == "" {
				if stderr.Len() != 0 {
					t.Errorf("unexpected stderr: %s", &stderr)
				}
			} else if !strings.Contains(stderr.String(), test.stderr) {
				t.Errorf("stderr = %q, want it to contain %q", stderr.String(), test.stderr)
			}
		})
	}
}

func TestCompletion(t *testing.T) {
	for _, shell := range []string{"bash", "zsh", "fish", "powershell"} {
		t.Run(shell, func(t *testing.T) {
			t.Parallel()
			var stdout, stderr bytes.Buffer
			if code := run([]string{"completion", shell}, "dev", &stdout, &stderr); code != 0 {
				t.Fatalf("exit code = %d; stderr: %s", code, &stderr)
			}
			if !strings.Contains(stdout.String(), "go-genuine") {
				t.Errorf("completion script does not target go-genuine: %s", &stdout)
			}
			if stderr.Len() != 0 {
				t.Errorf("unexpected stderr: %s", &stderr)
			}
		})
	}
}

func TestOutputFailure(t *testing.T) {
	var stderr bytes.Buffer
	code := run([]string{"version"}, "dev", failingWriter{}, &stderr)
	if code != 1 {
		t.Fatalf("exit code = %d, want 1", code)
	}
	if !strings.Contains(stderr.String(), "output unavailable") {
		t.Errorf("missing output error: %s", &stderr)
	}
	if strings.Contains(stderr.String(), "--help") {
		t.Errorf("execution error should not show a usage hint: %s", &stderr)
	}
}

type failingWriter struct{}

func (failingWriter) Write([]byte) (int, error) {
	return 0, errors.New("output unavailable")
}
