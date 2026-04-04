package seancesdomain

import (
	"context"
	"time"

	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
)

type Repository interface {
	GetList(ctx context.Context, owner userdomain.UUID) (Seances, error)
	GetLatestByOrg(ctx context.Context, org string) (Seances, error)
	Create(ctx context.Context, owner userdomain.UUID, errors int32, actions Actions, at time.Time, done time.Time) (*Seance, error)
}
