package repositories

import (
	"context"
	"encoding/json"
	"time"

	seancesdomain "github.com/aesterial/fire-step/backend/internal/domain/seances"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	"github.com/aesterial/fire-step/backend/internal/infra/db/sqlc"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"github.com/jackc/pgx/v5/pgtype"
)

type SeanceRepository struct {
	conn sqlc.Querier
}

func NewSeanceRepository(conn sqlc.Querier) *SeanceRepository {
	return &SeanceRepository{conn: conn}
}

var _ seancesdomain.Repository = (*SeanceRepository)(nil)

func (s *SeanceRepository) parseSeance(seance sqlc.Seance) *seancesdomain.Seance {
	var actions seancesdomain.Actions
	err := json.Unmarshal(seance.Actions, &actions)
	if err != nil {
		return nil
	}
	return &seancesdomain.Seance{
		ID:      userdomain.ParseUUIDBytes(seance.ID.Bytes),
		Owner:   userdomain.ParseUUIDBytes(seance.Owner.Bytes),
		Errors:  seance.Errors,
		Actions: actions,
		At:      seance.At.Time,
		Done:    seance.Done.Time,
	}
}

func (s *SeanceRepository) GetList(ctx context.Context, owner userdomain.UUID) (seancesdomain.Seances, error) {
	list, err := s.conn.GetUserSeances(ctx, owner.PGType())
	if err != nil {
		return nil, err
	}
	var resp = make(seancesdomain.Seances, len(list))
	for i, e := range list {
		resp[i] = s.parseSeance(e)
	}
	return resp, nil
}

func (s *SeanceRepository) GetLatestByOrg(ctx context.Context, org string) (seancesdomain.Seances, error) {
	list, err := s.conn.GetLatestSeancesByOrg(ctx, org)
	if err != nil {
		return nil, err
	}
	var resp = make(seancesdomain.Seances, len(list))
	for i, e := range list {
		resp[i] = s.parseSeance(e)
	}
	return resp, nil
}

func (s *SeanceRepository) Create(ctx context.Context, owner userdomain.UUID, errors int32, actions seancesdomain.Actions, at time.Time, done time.Time) (*seancesdomain.Seance, error) {
	if at.IsZero() || done.IsZero() {
		return nil, apperrors.InvalidArguments
	}
	acts, err := json.Marshal(actions)
	if err != nil {
		return nil, err
	}
	seance, err := s.conn.CreateUserSeance(ctx, sqlc.CreateUserSeanceParams{
		Owner:   owner.PGType(),
		Actions: acts,
		At: pgtype.Timestamptz{
			Time:  at,
			Valid: true,
		},
		Done: pgtype.Timestamptz{
			Time:  done,
			Valid: true,
		},
		Errors: errors,
	})
	return s.parseSeance(seance), nil
}
