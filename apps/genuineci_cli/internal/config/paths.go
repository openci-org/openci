package config

import (
	"errors"
	"path/filepath"

	"github.com/adrg/xdg"
)

type Paths struct {
	ConfigFile      string
	CredentialsFile string
}

func ResolvePaths() (Paths, error) {
	if xdg.ConfigHome == "" {
		return Paths{}, errors.New("resolve user config directory: XDG config home is unavailable")
	}
	configDir := filepath.Join(xdg.ConfigHome, "genuineci")

	return Paths{
		ConfigFile:      filepath.Join(configDir, "config.json"),
		CredentialsFile: filepath.Join(configDir, "credentials.json"),
	}, nil
}
