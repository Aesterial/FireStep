package loginservice

import (
	"context"

	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"golang.org/x/crypto/bcrypt"
)

func (s *Service) Register(ctx context.Context, username string, email string, initials string, password string, org string, device sessiondomain.DeviceType) (*userdomain.User, *userdomain.UUID, error) {
	if username == "" || email == "" || initials == "" || password == "" || org == "" {
		return nil, nil, apperrors.InvalidArguments
	}
	exists, err := s.usr.IsUsernameOrEmailExists(ctx, username, email)
	if err != nil {
		loggingservice.Error("login", "failed to check is username or email exists", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}
	if exists {
		return nil, nil, apperrors.AlreadyUsed
	}
	newpass, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		loggingservice.Error("login", "failed to generate password hash", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}
	usr, err := s.usr.Create(ctx, username, initials, email, string(newpass), org)
	if err != nil {
		loggingservice.Error("login", "failed to create user", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}
	session, err := s.ses.Create(ctx, usr.ID, device)
	if err != nil {
		loggingservice.Error("login", "failed to create session", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}
	return usr, &session.ID, nil
}
