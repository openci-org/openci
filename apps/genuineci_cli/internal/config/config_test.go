package config_test

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/adrg/xdg"
	"github.com/openci-org/openci/apps/genuineci_cli/internal/config"
)

func TestStoreLoadMissingFile(t *testing.T) {
	store, path := newSettingsStore(t)
	assertLanguage(t, store, "en")
	assertNoSettingsDirectory(t, path)
}

func TestStoreLoadMissingLanguage(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, "{}")
	assertLanguage(t, store, "en")
	assertSettingsContents(t, path, "{}")
}

func TestStoreLoadJapanese(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	assertLanguage(t, store, "ja")
}

func TestStoreLoadEnglish(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"en"}`)
	assertLanguage(t, store, "en")
}

func TestStoreLoadNullLanguage(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":null}`)
	assertLanguage(t, store, "en")
	assertSettingsContents(t, path, `{"language":null}`)
}

func TestStoreRejectsEmptyFile(t *testing.T) {
	assertRejectedSettings(t, "")
}

func TestStoreRejectsWhitespaceFile(t *testing.T) {
	assertRejectedSettings(t, " \n\t ")
}

func TestStoreRejectsMalformedJSON(t *testing.T) {
	assertRejectedSettings(t, `{"language":`)
}

func TestStoreRejectsTrailingJSON(t *testing.T) {
	assertRejectedSettings(t, `{"language":"ja"} {}`)
}

func TestStoreRejectsArrayRoot(t *testing.T) {
	assertRejectedSettings(t, `[{"language":"ja"}]`)
}

func TestStoreRejectsNullRoot(t *testing.T) {
	assertRejectedSettings(t, "null")
}

func TestStoreRejectsStringRoot(t *testing.T) {
	assertRejectedSettings(t, `"ja"`)
}

func TestStoreRejectsNumberRoot(t *testing.T) {
	assertRejectedSettings(t, "1")
}

func TestStoreRejectsBooleanRoot(t *testing.T) {
	assertRejectedSettings(t, "true")
}

func TestStoreRejectsNumberLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":1}`)
}

func TestStoreRejectsBooleanLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":true}`)
}

func TestStoreRejectsArrayLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":["ja"]}`)
}

func TestStoreRejectsObjectLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":{"name":"ja"}}`)
}

func TestStoreRejectsUnsupportedLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":"fr"}`)
}

func TestStoreRejectsEmptyLanguage(t *testing.T) {
	assertRejectedSettings(t, `{"language":""}`)
}

func TestStoreSetLanguageJapanese(t *testing.T) {
	store, path := newSettingsStore(t)
	if err := store.SetLanguage("ja"); err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, store, "ja")
	assertSettingsContents(t, path, "{\n  \"language\": \"ja\"\n}\n")

	reloaded, err := config.NewStore()
	if err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, reloaded, "ja")
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0o600 {
		t.Errorf("file mode = %o, want 600", info.Mode().Perm())
	}
	entries, err := os.ReadDir(filepath.Dir(path))
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || entries[0].Name() != "config.json" {
		t.Errorf("unexpected settings directory entries: %v", entries)
	}
}

func TestStoreSetLanguageEnglish(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	if err := store.SetLanguage("en"); err != nil {
		t.Fatal(err)
	}
	reloaded, err := config.NewStore()
	if err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, reloaded, "en")
}

func TestStoreSetLanguageRetainsOtherSettings(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"en","editor":{"theme":"dark"}}`)
	if err := store.SetLanguage("ja"); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var saved struct {
		Language string `json:"language"`
		Editor   struct {
			Theme string `json:"theme"`
		} `json:"editor"`
	}
	if err := json.Unmarshal(data, &saved); err != nil {
		t.Fatal(err)
	}
	if saved.Language != "ja" || saved.Editor.Theme != "dark" {
		t.Errorf("saved settings = %+v, want Japanese and the original editor theme", saved)
	}
}

func TestStoreRejectsInvalidLanguageUpdate(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	if err := store.SetLanguage("fr"); err == nil {
		t.Fatal("expected an error for an unsupported language")
	}
	assertSettingsContents(t, path, `{"language":"ja"}`)
	assertLanguage(t, store, "ja")
}

func TestStoreInvalidUpdateDoesNotCreateFiles(t *testing.T) {
	store, path := newSettingsStore(t)
	if err := store.SetLanguage(""); err == nil {
		t.Fatal("expected an error for an empty language")
	}
	assertNoSettingsDirectory(t, path)
}

func TestStoreInstancesAreIndependent(t *testing.T) {
	first, _ := newSettingsStore(t)
	if err := first.SetLanguage("ja"); err != nil {
		t.Fatal(err)
	}
	second, secondPath := newSettingsStore(t)
	assertLanguage(t, second, "en")
	assertNoSettingsDirectory(t, secondPath)
	if err := second.SetLanguage("en"); err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, first, "ja")
	assertLanguage(t, second, "en")
}

func TestStoreReloadAfterFileRemoval(t *testing.T) {
	store, path := newSettingsStore(t)
	if err := store.SetLanguage("ja"); err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, store, "ja")
	if err := os.Remove(path); err != nil {
		t.Fatal(err)
	}
	assertLanguage(t, store, "en")
	if _, err := os.Stat(path); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("file stat error = %v, want file to remain absent", err)
	}
}

func TestStoreReloadRejectsInvalidFile(t *testing.T) {
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	assertLanguage(t, store, "ja")
	writeSettingsJSON(t, path, "invalid")
	if _, err := store.Load(); err == nil {
		t.Fatal("expected an error instead of cached settings")
	}
	assertSettingsContents(t, path, "invalid")
}

func TestStoreRejectsDirectory(t *testing.T) {
	store, path := newSettingsStore(t)
	if err := os.MkdirAll(path, 0o700); err != nil {
		t.Fatal(err)
	}
	if _, err := store.Load(); err == nil {
		t.Fatal("expected an error when config.json is a directory")
	}
	if err := store.SetLanguage("ja"); err == nil {
		t.Fatal("expected an error instead of replacing the directory")
	}
	info, err := os.Stat(path)
	if err != nil || !info.IsDir() {
		t.Fatalf("settings directory was changed: %v", err)
	}
}

func TestStoreRejectsUnreadableFile(t *testing.T) {
	if os.Geteuid() == 0 {
		t.Skip("root can read files without read permission")
	}
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	if err := os.Chmod(path, 0o000); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.Chmod(path, 0o600) })
	if _, err := store.Load(); !errors.Is(err, os.ErrPermission) {
		t.Fatalf("load error = %v, want permission error", err)
	}
	if err := store.SetLanguage("en"); !errors.Is(err, os.ErrPermission) {
		t.Fatalf("save error = %v, want permission error", err)
	}
	if err := os.Chmod(path, 0o600); err != nil {
		t.Fatal(err)
	}
	assertSettingsContents(t, path, `{"language":"ja"}`)
}

func TestStoreWriteFailurePreservesSettings(t *testing.T) {
	if os.Geteuid() == 0 {
		t.Skip("root can write directories without write permission")
	}
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, `{"language":"ja"}`)
	dir := filepath.Dir(path)
	if err := os.Chmod(dir, 0o500); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.Chmod(dir, 0o700) })
	if err := store.SetLanguage("en"); !errors.Is(err, os.ErrPermission) {
		t.Fatalf("save error = %v, want permission error", err)
	}
	assertLanguage(t, store, "ja")
	assertSettingsContents(t, path, `{"language":"ja"}`)
}

func TestNewStoreRequiresConfigHome(t *testing.T) {
	original := xdg.ConfigHome
	t.Cleanup(func() { xdg.ConfigHome = original })
	xdg.ConfigHome = ""
	store, err := config.NewStore()
	if err == nil || store != nil {
		t.Fatalf("store = %v, error = %v, want an error and no store", store, err)
	}
}

func newSettingsStore(t *testing.T) (*config.Store, string) {
	t.Helper()
	original := xdg.ConfigHome
	t.Cleanup(func() { xdg.ConfigHome = original })
	xdg.ConfigHome = t.TempDir()
	store, err := config.NewStore()
	if err != nil {
		t.Fatal(err)
	}
	return store, filepath.Join(xdg.ConfigHome, "genuineci", "config.json")
}

func writeSettingsJSON(t *testing.T, path, contents string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(contents), 0o600); err != nil {
		t.Fatal(err)
	}
}

func assertLanguage(t *testing.T, store *config.Store, want string) {
	t.Helper()
	settings, err := store.Load()
	if err != nil {
		t.Fatal(err)
	}
	if settings.Language != want {
		t.Errorf("language = %q, want %q", settings.Language, want)
	}
}

func assertSettingsContents(t *testing.T, path, want string) {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != want {
		t.Errorf("settings contents = %q, want %q", data, want)
	}
}

func assertNoSettingsDirectory(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Stat(filepath.Dir(path)); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("directory stat error = %v, want no settings directory", err)
	}
}

func assertRejectedSettings(t *testing.T, contents string) {
	t.Helper()
	store, path := newSettingsStore(t)
	writeSettingsJSON(t, path, contents)
	if _, err := store.Load(); err == nil {
		t.Fatal("expected invalid settings to fail loading")
	}
	if err := store.SetLanguage("en"); err == nil {
		t.Fatal("expected invalid settings to fail saving")
	}
	assertSettingsContents(t, path, contents)
}
