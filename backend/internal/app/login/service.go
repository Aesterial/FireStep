package loginservice

import (
	sessionservice "github.com/aesterial/fire-step/backend/internal/app/sessions"
	userservice "github.com/aesterial/fire-step/backend/internal/app/user"
)

type Service struct {
	usr *userservice.Service
	ses *sessionservice.Service
}

func NewLoginService(usr *userservice.Service, ses *sessionservice.Service) *Service {
	return &Service{
		usr: usr,
		ses: ses,
	}
}
