package loginservice

import (
	"context"
	"errors"

	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"github.com/jackc/pgx/v5"
	"golang.org/x/crypto/bcrypt"
)

func (s *Service) Login(ctx context.Context, username string, password string, device sessiondomain.DeviceType) (*userdomain.User, *userdomain.UUID, error) {
	if username == "" || password == "" {
		return nil, nil, apperrors.InvalidArguments
	}
	if !device.IsValid() {
		return nil, nil, apperrors.InvalidArguments
	}

	hash, err := s.usr.Password(ctx, username)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil, apperrors.Unauthenticated
		}
		loggingservice.Error("login", "failed to load password hash", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}
	if err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)); err != nil {
		return nil, nil, apperrors.Unauthenticated
	}

	usr, err := s.usr.ByUsername(ctx, username)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil, apperrors.Unauthenticated
		}
		loggingservice.Error("login", "failed to load user", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}

	session, err := s.ses.Create(ctx, usr.ID, device)
	if err != nil {
		loggingservice.Error("login", "failed to create session", loggingservice.FD("error", err))
		return nil, nil, apperrors.Wrap(err)
	}

	return usr, &session.ID, nil
}
