package config

import (
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestWriteFileCreatesParentDirectories(t *testing.T) {
	path := filepath.Join(t.TempDir(), "settings", "genuineci", "config.json")
	if err := WriteFile(path, []byte(`{"language":"ja"}`), 0o640); err != nil {
		t.Fatal(err)
	}
	assertFileContents(t, path, `{"language":"ja"}`)
	assertOnlyDestination(t, path)
	assertFileMode(t, path, 0o640)
	assertFileMode(t, filepath.Dir(path), 0o700)
}

func TestWriteFileReplacesCredentials(t *testing.T) {
	path := filepath.Join(t.TempDir(), "credentials.json")
	if err := os.WriteFile(path, []byte("previous synthetic credentials"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(path, 0o644); err != nil {
		t.Fatal(err)
	}
	if err := WriteFile(path, []byte("synthetic-token"), 0o600); err != nil {
		t.Fatal(err)
	}
	assertFileContents(t, path, "synthetic-token")
	assertOnlyDestination(t, path)
	assertFileMode(t, path, 0o600)
}

func TestWriteFileEmptyContents(t *testing.T) {
	path := filepath.Join(t.TempDir(), "config.json")
	if err := WriteFile(path, nil, 0o600); err != nil {
		t.Fatal(err)
	}
	assertFileContents(t, path, "")
	assertOnlyDestination(t, path)
}

func TestWriteFileParentIsFile(t *testing.T) {
	parent := filepath.Join(t.TempDir(), "settings")
	if err := os.WriteFile(parent, []byte("original"), 0o600); err != nil {
		t.Fatal(err)
	}
	err := WriteFile(filepath.Join(parent, "config.json"), []byte("synthetic-token"), 0o600)
	if err == nil {
		t.Fatal("expected an error for a parent that is a file")
	}
	assertFileContents(t, parent, "original")
	assertOnlyDestination(t, parent)
}

func TestWriteFileReplacementFailure(t *testing.T) {
	path := filepath.Join(t.TempDir(), "credentials.json")
	if err := os.Mkdir(path, 0o700); err != nil {
		t.Fatal(err)
	}
	original := filepath.Join(path, "original")
	if err := os.WriteFile(original, []byte("original"), 0o600); err != nil {
		t.Fatal(err)
	}
	err := WriteFile(path, []byte("synthetic-token"), 0o600)
	if err == nil {
		t.Fatal("expected an error when replacing a directory")
	}
	var renameErr *os.LinkError
	if !errors.As(err, &renameErr) || renameErr.Op != "rename" {
		t.Fatalf("error = %v, want a rename error", err)
	}
	assertFileContents(t, original, "original")
	assertOnlyDestination(t, path)
	if strings.Contains(err.Error(), "synthetic-token") {
		t.Error("error contains file contents")
	}
}

func TestWriteFilePermissionFailure(t *testing.T) {
	path, file := prepareFailedWrite(t)
	wantErr := errors.New("permissions unavailable")
	file.chmodErr = wantErr
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, wantErr)
	if file.wrote {
		t.Error("wrote data before permissions were applied")
	}
}

func TestWriteFileWriteFailure(t *testing.T) {
	path, file := prepareFailedWrite(t)
	wantErr := errors.New("disk full")
	file.writeErr = wantErr
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, wantErr)
}

func TestWriteFileShortWrite(t *testing.T) {
	path, file := prepareFailedWrite(t)
	file.shortWrite = true
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, io.ErrShortWrite)
}

func TestWriteFileSyncFailure(t *testing.T) {
	path, file := prepareFailedWrite(t)
	wantErr := errors.New("sync failed")
	file.syncErr = wantErr
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, wantErr)
}

func TestWriteFileCloseFailure(t *testing.T) {
	path, file := prepareFailedWrite(t)
	wantErr := errors.New("close failed")
	file.closeErr = wantErr
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, wantErr)
}

func TestWriteFileKeepsOriginalErrorWhenCleanupCloseFails(t *testing.T) {
	path, file := prepareFailedWrite(t)
	file.writeErr = errors.New("disk full")
	file.closeErr = errors.New("close failed")
	err := writeFile(file, path, []byte("synthetic-token"), 0o600)
	assertFailedWrite(t, path, err, file.writeErr)
	if !errors.Is(err, file.closeErr) {
		t.Errorf("error = %v, want cleanup close error too", err)
	}
}

func prepareFailedWrite(t *testing.T) (string, *failingTempFile) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "credentials.json")
	if err := os.WriteFile(path, []byte("original"), 0o600); err != nil {
		t.Fatal(err)
	}
	file, err := os.CreateTemp(filepath.Dir(path), ".credentials.json.*")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = file.Close() })
	return path, &failingTempFile{File: file}
}

func assertFailedWrite(t *testing.T, path string, err, wantErr error) {
	t.Helper()
	if !errors.Is(err, wantErr) {
		t.Fatalf("error = %v, want %v", err, wantErr)
	}
	if strings.Contains(err.Error(), "synthetic-token") {
		t.Error("error contains file contents")
	}
	assertFileContents(t, path, "original")
	assertOnlyDestination(t, path)
}

func assertFileContents(t *testing.T, path, want string) {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if string(data) != want {
		t.Errorf("file contents = %q, want %q", data, want)
	}
}

func assertOnlyDestination(t *testing.T, path string) {
	t.Helper()
	entries, err := os.ReadDir(filepath.Dir(path))
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || entries[0].Name() != filepath.Base(path) {
		t.Errorf("unexpected directory entries: %v", entries)
	}
}

func assertFileMode(t *testing.T, path string, want os.FileMode) {
	t.Helper()
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if got := info.Mode().Perm(); got != want {
		t.Errorf("file mode = %o, want %o", got, want)
	}
}

// Use real temporary files while simulating failures that are hard to trigger reliably.
type failingTempFile struct {
	*os.File
	chmodErr   error
	writeErr   error
	syncErr    error
	closeErr   error
	shortWrite bool
	wrote      bool
}

func (f *failingTempFile) Chmod(mode os.FileMode) error {
	if f.chmodErr != nil {
		return f.chmodErr
	}
	return f.File.Chmod(mode)
}

func (f *failingTempFile) Write(data []byte) (int, error) {
	f.wrote = true
	if f.writeErr != nil || f.shortWrite {
		n, err := f.File.Write(data[:len(data)/2])
		if err != nil {
			return n, err
		}
		return n, f.writeErr
	}
	return f.File.Write(data)
}

func (f *failingTempFile) Sync() error {
	if f.syncErr != nil {
		return f.syncErr
	}
	return f.File.Sync()
}

func (f *failingTempFile) Close() error {
	return errors.Join(f.File.Close(), f.closeErr)
}
