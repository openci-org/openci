package config

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"github.com/spf13/viper"
)

type Settings struct {
	Language string
}

type Store struct {
	path   string
	values *viper.Viper
}

func NewStore() (*Store, error) {
	paths, err := ResolvePaths()
	if err != nil {
		return nil, err
	}
	values := viper.New()
	values.SetConfigType("json")
	values.SetDefault("language", "en")
	return &Store{path: paths.ConfigFile, values: values}, nil
}

func (s *Store) Load() (Settings, error) {
	data, err := os.ReadFile(s.path)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			return Settings{}, fmt.Errorf("read settings: %w", err)
		}
		data = []byte("{}")
	}
	data = bytes.TrimSpace(data)
	if len(data) == 0 || data[0] != '{' {
		return Settings{}, errors.New("settings must contain a JSON object")
	}
	if err := s.values.ReadConfig(bytes.NewReader(data)); err != nil {
		return Settings{}, fmt.Errorf("parse settings: %w", err)
	}

	language, ok := s.values.Get("language").(string)
	if !ok {
		return Settings{}, errors.New("language must be a string, null, or omitted")
	}
	if err := validateLanguage(language); err != nil {
		return Settings{}, err
	}
	return Settings{Language: language}, nil
}

func (s *Store) SetLanguage(language string) error {
	if err := validateLanguage(language); err != nil {
		return err
	}
	if _, err := s.Load(); err != nil {
		return err
	}
	settings := s.values.AllSettings()
	settings["language"] = language
	data, err := json.MarshalIndent(settings, "", "  ")
	if err != nil {
		return fmt.Errorf("encode settings: %w", err)
	}
	return WriteFile(s.path, append(data, '\n'), 0o600)
}

func validateLanguage(language string) error {
	if language != "ja" && language != "en" {
		return errors.New("language must be \"ja\" or \"en\"")
	}
	return nil
}
