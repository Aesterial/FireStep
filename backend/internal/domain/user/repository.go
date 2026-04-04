package userdomain

import "context"

type Repository interface {
	CreateUser(ctx context.Context, username string, initals string, email string, password string, org string) (*User, error)
	GetUser(ctx context.Context, id UUID) (*User, error)
	GetUserByUsername(ctx context.Context, username string) (*User, error)
	IsExists(ctx context.Context, id UUID) (bool, error)
	IsAdmin(ctx context.Context, id UUID) (bool, error)
	IsUsernameOrEmailExists(ctx context.Context, username string, email string) (bool, error)
	GetPassword(ctx context.Context, username string) (string, error)
	GetUsers(ctx context.Context, org string) (Users, error)
	GetUsersCount(ctx context.Context, org string) (int64, error)
}
