package repositories

import (
	"context"

	statsdomain "github.com/aesterial/fire-step/backend/internal/domain/stats"
	"github.com/aesterial/fire-step/backend/internal/infra/db/sqlc"
)

type StatsRepository struct {
	conn sqlc.Querier
}

func NewStatsRepository(conn sqlc.Querier) *StatsRepository {
	return &StatsRepository{conn: conn}
}

var _ statsdomain.Repository = (*StatsRepository)(nil)

func (s *StatsRepository) GetTitleStats(ctx context.Context, org string) (int32, int32, int32, error) {
	row, err := s.conn.GetSeanceStatsByOrg(ctx, org)
	if err != nil {
		return 0, 0, 0, err
	}

	var errors int32
	if e, ok := row.TotalErrors.(int64); ok {
		errors = int32(e)
	}

	return int32(row.TotalSeances), errors, int32(row.AvgExecutionTimeSeconds), nil
}

func (s *StatsRepository) GetErrorsPerHour(ctx context.Context, org string) (statsdomain.GraphPoints, error) {
	rows, err := s.conn.GetErrorsPerHourByOrg(ctx, org)
	if err != nil {
		return nil, err
	}
	var resp = make(statsdomain.GraphPoints, len(rows))
	for i, r := range rows {
		resp[i] = &statsdomain.GraphPoint{
			At:    r.Hour.Time,
			Value: r.Count,
		}
	}
	return resp, nil
}

func (s *StatsRepository) GetActivityByDay(ctx context.Context, org string) (statsdomain.GraphPoints, error) {
	rows, err := s.conn.GetActivityByDayByOrg(ctx, org)
	if err != nil {
		return nil, err
	}
	var resp = make(statsdomain.GraphPoints, len(rows))
	for i, r := range rows {
		resp[i] = &statsdomain.GraphPoint{
			At:    r.Day.Time,
			Value: r.Count,
		}
	}
	return resp, nil
}
