package userservice

import (
	"context"

	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
)

type Service struct {
	usr userdomain.Repository
}

func NewUserService(usr userdomain.Repository) *Service {
	return &Service{usr: usr}
}

func (s *Service) Create(ctx context.Context, username string, initals string, email string, password string, org string) (*userdomain.User, error) {
	return s.usr.CreateUser(ctx, username, initals, email, password, org)
}

func (s *Service) Info(ctx context.Context, id userdomain.UUID) (*userdomain.User, error) {
	return s.usr.GetUser(ctx, id)
}

func (s *Service) ByUsername(ctx context.Context, username string) (*userdomain.User, error) {
	if username == "" {
		return nil, apperrors.InvalidArguments
	}
	return s.usr.GetUserByUsername(ctx, username)
}

func (s *Service) Exists(ctx context.Context, id userdomain.UUID) (bool, error) {
	return s.usr.IsExists(ctx, id)
}

func (s *Service) IsUsernameOrEmailExists(ctx context.Context, username string, email string) (bool, error) {
	if username == "" || email == "" {
		return false, apperrors.InvalidArguments
	}
	return s.usr.IsUsernameOrEmailExists(ctx, username, email)
}

func (s *Service) Password(ctx context.Context, username string) (string, error) {
	if username == "" {
		return "", apperrors.InvalidArguments
	}
	return s.usr.GetPassword(ctx, username)
}

func (s *Service) List(ctx context.Context, org string) (userdomain.Users, error) {
	if org == "" {
		return nil, apperrors.InvalidArguments
	}
	return s.usr.GetUsers(ctx, org)
}

func (s *Service) Count(ctx context.Context, org string) (int64, error) {
	if org == "" {
		return 0, apperrors.InvalidArguments
	}
	return s.usr.GetUsersCount(ctx, org)
}

func (s *Service) IsAdmin(ctx context.Context, id userdomain.UUID) (bool, error) {
	return s.usr.IsAdmin(ctx, id)
}
