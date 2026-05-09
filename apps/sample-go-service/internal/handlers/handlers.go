package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ohanyere/enterprise-kubernetes-delivery-platform/apps/sample-go-service/internal/config"
)

type Handler struct {
	config config.Config
}

func New(cfg config.Config) *Handler {
	return &Handler{config: cfg}
}

func (h *Handler) Register(mux *http.ServeMux) {
	mux.HandleFunc("/health", h.health)
	mux.HandleFunc("/ready", h.ready)
	mux.HandleFunc("/version", h.version)
	mux.HandleFunc("/config", h.runtimeConfig)
}

func (h *Handler) health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ready(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (h *Handler) version(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"app_version":     h.config.AppVersion,
		"environment":     h.config.AppEnv,
		"commit_sha":      h.config.CommitSHA,
		"release_channel": h.config.ReleaseChannel,
	})
}

func (h *Handler) runtimeConfig(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"app_env":              h.config.AppEnv,
		"log_level":            h.config.LogLevel,
		"release_channel":      h.config.ReleaseChannel,
		"feature_flag_example": h.config.FeatureFlagExample,
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(payload); err != nil {
		http.Error(w, "failed to encode response", http.StatusInternalServerError)
	}
}
