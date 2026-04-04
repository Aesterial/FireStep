package loginservice

import (
	"context"

	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
)

func (s *Service) Logout(ctx context.Context, id userdomain.UUID) error {
	if err := s.ses.Revoke(ctx, id); err != nil {
		loggingservice.Error("login", "failed to logout session", loggingservice.FD("err", err))
		return apperrors.Wrap(err)
	}
	return nil
}
