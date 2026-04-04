package seanceservice

import (
	"context"
	"time"

	seancesdomain "github.com/aesterial/fire-step/backend/internal/domain/seances"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
)

type Service struct {
	seances seancesdomain.Repository
}

func NewSeanceService(seances seancesdomain.Repository) *Service {
	return &Service{seances: seances}
}

func (s *Service) GetList(ctx context.Context, id userdomain.UUID) (seancesdomain.Seances, error) {
	return s.seances.GetList(ctx, id)
}

func (s *Service) Create(ctx context.Context, owner userdomain.UUID, errors int32, actions seancesdomain.Actions, at time.Time, done time.Time) (*seancesdomain.Seance, error) {
	return s.seances.Create(ctx, owner, errors, actions, at, done)
}
