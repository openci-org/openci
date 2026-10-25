package config_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/adrg/xdg"
	"github.com/openci-org/openci/apps/genuineci_cli/internal/config"
)

func TestResolvePaths(t *testing.T) {
	root := t.TempDir()
	configHome := filepath.Join(root, "xdg")

	// Reload only in tests, after changing the environment and after restoring it.
	t.Cleanup(xdg.Reload)
	t.Setenv("HOME", root)
	t.Setenv("XDG_CONFIG_HOME", configHome)
	xdg.Reload()
	if xdg.ConfigHome != configHome {
		t.Fatalf("XDG config home = %q, want %q", xdg.ConfigHome, configHome)
	}

	got, err := config.ResolvePaths()
	if err != nil {
		t.Fatal(err)
	}
	want := config.Paths{
		ConfigFile:      filepath.Join(configHome, "genuineci", "config.json"),
		CredentialsFile: filepath.Join(configHome, "genuineci", "credentials.json"),
	}
	if got != want {
		t.Errorf("paths = %+v, want %+v", got, want)
	}

	entries, err := os.ReadDir(root)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 0 {
		t.Errorf("resolving paths created files or directories: %v", entries)
	}
}

func TestResolvePathsMissingConfigHome(t *testing.T) {
	originalConfigHome := xdg.ConfigHome
	t.Cleanup(func() {
		xdg.ConfigHome = originalConfigHome
	})
	xdg.ConfigHome = ""

	got, err := config.ResolvePaths()
	if err == nil {
		t.Fatal("expected an error when XDG config home is unavailable")
	}
	if got != (config.Paths{}) {
		t.Errorf("paths = %+v, want empty paths on error", got)
	}
}
