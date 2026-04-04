package configservice

import (
	"os"
	"strconv"
	"strings"

	configdomain "github.com/aesterial/fire-step/backend/internal/domain/config"
	"github.com/joho/godotenv"
)

var cfg configdomain.Config

func parseType[T any](str string, def T) T {
	s := strings.TrimSpace(str)
	if s == "" {
		return def
	}
	switch any(def).(type) {
	case int:
		v, err := strconv.Atoi(s)
		if err != nil {
			return def
		}
		return any(v).(T)
	case bool:
		v, err := strconv.ParseBool(s)
		if err != nil {
			return def
		}
		return any(v).(T)
	case string:
		return any(s).(T)
	case float64:
		v, err := strconv.ParseFloat(s, 64)
		if err != nil {
			return def
		}
		return any(v).(T)
	default:
		return def
	}
}

func Ensure() bool {
	_ = godotenv.Load(".env")
	cfg = configdomain.Config{
		Database: configdomain.Database{
			Name:     os.Getenv("POSTGRES_DB"),
			Host:     os.Getenv("POSTGRES_HOST"),
			Port:     os.Getenv("POSTGRES_PORT"),
			TLS:      configdomain.DbTls(os.Getenv("POSTGRES_TLS_MODE")),
			CaPath:   new(os.Getenv("POSTGRES_CERT_PATH")),
			User:     os.Getenv("POSTGRES_USER"),
			Password: os.Getenv("POSTGRES_PASS"),
		},
		Mode: func() configdomain.Mode {
			if parseType(os.Getenv("IS_DEBUG"), false) {
				return configdomain.ModeDebug
			}
			return configdomain.ModeProduction
		}(),
		Port: os.Getenv("PORT"),
	}
	cfg.MarkLoaded()
	return cfg.IsDatabaseValid()
}

func Get() configdomain.Config {
	if !cfg.IsLoaded() {
		Ensure()
	}
	return cfg
}
