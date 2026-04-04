package repositories

import (
	"context"
	"errors"

	"github.com/aesterial/fire-step/backend/internal/domain/user"
	"github.com/aesterial/fire-step/backend/internal/infra/db/sqlc"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"github.com/jackc/pgx/v5"
)

type UserRepository struct {
	conn sqlc.Querier
}

var _ userdomain.Repository = (*UserRepository)(nil)

func NewUserRepository(conn sqlc.Querier) *UserRepository {
	return &UserRepository{conn: conn}
}

func (u *UserRepository) CreateUser(ctx context.Context, username string, initals string, email string, password string, org string) (*userdomain.User, error) {
	if username == "" || initals == "" || email == "" || org == "" {
		return nil, apperrors.InvalidArguments
	}
	usr, err := u.conn.CreateUser(ctx, sqlc.CreateUserParams{
		Username: username,
		Email:    email,
		Password: password,
		Org:      org,
		Initials: initals,
	})
	if err != nil {
		return nil, err
	}
	return &userdomain.User{
		ID:           userdomain.ParseUUIDBytes(usr.ID.Bytes),
		Username:     usr.Username,
		Initials:     usr.Initials,
		Email:        usr.Email,
		Organization: usr.Org,
		AdminAccess:  usr.AdminAccess,
		Joined:       usr.Joinedat.Time,
	}, nil
}

func (u *UserRepository) GetUser(ctx context.Context, id userdomain.UUID) (*userdomain.User, error) {
	usr, err := u.conn.GetUser(ctx, id.PGType())
	if err != nil {
		return nil, err
	}
	return &userdomain.User{
		ID:           id,
		Username:     usr.Username,
		Initials:     usr.Initials,
		Email:        usr.Email,
		Organization: usr.Org,
		AdminAccess:  usr.AdminAccess,
		Joined:       usr.Joinedat.Time,
	}, nil
}

func (u *UserRepository) GetUserByUsername(ctx context.Context, username string) (*userdomain.User, error) {
	if username == "" {
		return nil, apperrors.InvalidArguments
	}
	usr, err := u.conn.GetUserByUsername(ctx, username)
	if err != nil {
		return nil, err
	}
	return &userdomain.User{
		ID:           userdomain.ParseUUIDBytes(usr.ID.Bytes),
		Username:     usr.Username,
		Initials:     usr.Initials,
		Email:        usr.Email,
		Organization: usr.Org,
		AdminAccess:  usr.AdminAccess,
		Joined:       usr.Joinedat.Time,
	}, nil
}

func (u *UserRepository) GetPassword(ctx context.Context, username string) (string, error) {
	if username == "" {
		return "", apperrors.InvalidArguments
	}
	return u.conn.GetPasswordByUsername(ctx, username)
}

func (u *UserRepository) GetUsers(ctx context.Context, org string) (userdomain.Users, error) {
	if org == "" {
		return nil, apperrors.InvalidArguments
	}
	usrs, err := u.conn.GetUsersByOrg(ctx, org)
	if err != nil {
		return nil, err
	}
	var users = make(userdomain.Users, len(usrs))
	for i, e := range usrs {
		users[i] = &userdomain.User{ID: userdomain.ParseUUIDBytes(e.ID.Bytes), Username: e.Username, Email: e.Email, Initials: e.Initials, AdminAccess: e.AdminAccess, Joined: e.Joinedat.Time}
	}
	return users, nil
}

func (u *UserRepository) GetUsersCount(ctx context.Context, org string) (int64, error) {
	if org == "" {
		return 0, apperrors.InvalidArguments
	}
	return u.conn.GetUsersCountByOrg(ctx, org)
}

func (u *UserRepository) IsExists(ctx context.Context, id userdomain.UUID) (bool, error) {
	exists, err := u.conn.IsUserExists(ctx, id.PGType())
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	return exists, nil
}

func (u *UserRepository) IsUsernameOrEmailExists(ctx context.Context, username string, email string) (bool, error) {
	exists, err := u.conn.IsUsernameOrEmailExists(ctx, sqlc.IsUsernameOrEmailExistsParams{
		Username: username,
		Email:    email,
	})
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	return exists, nil
}

func (u *UserRepository) IsAdmin(ctx context.Context, id userdomain.UUID) (bool, error) {
	exists, err := u.IsExists(ctx, id)
	if err != nil {
		return false, err
	}
	if !exists {
		return false, nil
	}
	return u.conn.IsUserAdmin(ctx, id.PGType())
}
