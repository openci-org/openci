package config

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func WriteFile(path string, data []byte, mode os.FileMode) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return fmt.Errorf("create settings directory: %w", err)
	}
	file, err := os.CreateTemp(dir, "."+filepath.Base(path)+".*")
	if err != nil {
		return fmt.Errorf("create temporary settings file: %w", err)
	}
	return writeFile(file, path, data, mode)
}

type temporaryFile interface {
	io.WriteCloser
	Name() string
	Chmod(os.FileMode) error
	Sync() error
}

func writeFile(file temporaryFile, path string, data []byte, mode os.FileMode) (err error) {
	name := file.Name()
	closed := false
	defer func() {
		if !closed {
			if closeErr := file.Close(); closeErr != nil {
				err = errors.Join(err, fmt.Errorf("close temporary settings file: %w", closeErr))
			}
		}
		if err != nil {
			if removeErr := os.Remove(name); removeErr != nil && !errors.Is(removeErr, os.ErrNotExist) {
				err = errors.Join(err, fmt.Errorf("remove temporary settings file: %w", removeErr))
			}
		}
	}()

	if err := file.Chmod(mode); err != nil {
		return fmt.Errorf("set settings file permissions: %w", err)
	}
	n, err := file.Write(data)
	if err != nil {
		return fmt.Errorf("write settings file: %w", err)
	}
	if n != len(data) {
		return fmt.Errorf("write settings file: %w", io.ErrShortWrite)
	}
	if err := file.Sync(); err != nil {
		return fmt.Errorf("sync settings file: %w", err)
	}
	err = file.Close()
	closed = true
	if err != nil {
		return fmt.Errorf("close settings file: %w", err)
	}
	if err := os.Rename(name, path); err != nil {
		return fmt.Errorf("replace settings file: %w", err)
	}
	return nil
}
