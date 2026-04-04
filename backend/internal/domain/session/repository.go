package sessiondomain

import (
	"context"

	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
)

type Repository interface {
	Create(ctx context.Context, owner userdomain.UUID, deviceType DeviceType) (*Session, error)
	List(ctx context.Context, owner userdomain.UUID) (Sessions, error)
	Revoke(ctx context.Context, id userdomain.UUID) error
	IsValid(ctx context.Context, sessionID userdomain.UUID, deviceType DeviceType) (bool, error)
	IsExists(ctx context.Context, id userdomain.UUID) (bool, error)
	LastSeen(ctx context.Context, id userdomain.UUID) error
	GetOwner(ctx context.Context, id userdomain.UUID) (*userdomain.UUID, error)
}
