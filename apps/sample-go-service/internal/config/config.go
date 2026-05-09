package config

import "os"

type Config struct {
	AppEnv             string `json:"app_env"`
	LogLevel           string `json:"log_level"`
	ReleaseChannel     string `json:"release_channel"`
	AppVersion         string `json:"app_version"`
	CommitSHA          string `json:"commit_sha"`
	FeatureFlagExample string `json:"feature_flag_example"`
}

func Load() Config {
	return Config{
		AppEnv:             envOrDefault("APP_ENV", "local"),
		LogLevel:           envOrDefault("LOG_LEVEL", "debug"),
		ReleaseChannel:     envOrDefault("RELEASE_CHANNEL", "local"),
		AppVersion:         envOrDefault("APP_VERSION", "0.0.0-local"),
		CommitSHA:          envOrDefault("COMMIT_SHA", "unknown"),
		FeatureFlagExample: envOrDefault("FEATURE_FLAG_EXAMPLE", "false"),
	}
}

func envOrDefault(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}

	return value
}
