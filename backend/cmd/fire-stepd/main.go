package main

import (
	configservice "github.com/aesterial/fire-step/backend/internal/app/config"
	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
)

func main() {
	logger := loggingservice.NewLogger()
	logger.SetDefault()
	if !configservice.Ensure() {
		loggingservice.Info("main", "failed to init config")
		return
	}

}
