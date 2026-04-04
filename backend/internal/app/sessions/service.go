package sessionservice

import (
	"context"

	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
)

type Service struct {
	ses sessiondomain.Repository
}

func NewSessionService(ses sessiondomain.Repository) *Service {
	return &Service{ses: ses}
}

func (s *Service) Create(ctx context.Context, owner userdomain.UUID, deviceType sessiondomain.DeviceType) (*sessiondomain.Session, error) {
	if !deviceType.IsValid() {
		return nil, apperrors.InvalidArguments
	}
	return s.ses.Create(ctx, owner, deviceType)
}

func (s *Service) List(ctx context.Context, owner userdomain.UUID) (sessiondomain.Sessions, error) {
	return s.ses.List(ctx, owner)
}

func (s *Service) Revoke(ctx context.Context, id userdomain.UUID) error {
	exists, err := s.ses.IsExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return apperrors.RecordNotFound
	}
	return s.ses.Revoke(ctx, id)
}

func (s *Service) IsValid(ctx context.Context, sessionID userdomain.UUID, deviceType sessiondomain.DeviceType) (bool, error) {
	if !deviceType.IsValid() {
		return false, nil
	}
	return s.ses.IsValid(ctx, sessionID, deviceType)
}

func (s *Service) SetLastSeen(ctx context.Context, id userdomain.UUID) error {
	return s.ses.LastSeen(ctx, id)
}

func (s *Service) GetOwner(ctx context.Context, id userdomain.UUID) (*userdomain.UUID, error) {
	return s.ses.GetOwner(ctx, id)
}
