package statsservice

import (
	"context"

	seancesdomain "github.com/aesterial/fire-step/backend/internal/domain/seances"
	statsdomain "github.com/aesterial/fire-step/backend/internal/domain/stats"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
)

type UserService interface {
	Info(ctx context.Context, id userdomain.UUID) (*userdomain.User, error)
}

type SeanceService interface {
	GetLatestByOrg(ctx context.Context, org string) (seancesdomain.Seances, error)
}

type Service struct {
	stats   statsdomain.Repository
	seances SeanceService
	users   UserService
}

func NewStatsService(stats statsdomain.Repository, seances SeanceService, users UserService) *Service {
	return &Service{
		stats:   stats,
		seances: seances,
		users:   users,
	}
}

func (s *Service) getOrgAndCheckAdmin(ctx context.Context, userID userdomain.UUID) (string, error) {
	user, err := s.users.Info(ctx, userID)
	if err != nil {
		return "", err
	}
	if !user.AdminAccess {
		return "", apperrors.AccessDenied
	}
	return user.Organization, nil
}

func (s *Service) GetTitleStats(ctx context.Context, userID userdomain.UUID) (*statsdomain.TitleStats, error) {
	org, err := s.getOrgAndCheckAdmin(ctx, userID)
	if err != nil {
		return nil, err
	}

	seanceCount, errorsCount, avgSeconds, err := s.stats.GetTitleStats(ctx, org)
	if err != nil {
		return nil, err
	}

	latest, err := s.seances.GetLatestByOrg(ctx, org)
	if err != nil {
		return nil, err
	}

	return &statsdomain.TitleStats{
		Seances:    seanceCount,
		Errors:     errorsCount,
		AvgSeconds: avgSeconds,
		Latest:     latest,
	}, nil
}

func (s *Service) GetGraphStats(ctx context.Context, userID userdomain.UUID) (*statsdomain.GraphStats, error) {
	org, err := s.getOrgAndCheckAdmin(ctx, userID)
	if err != nil {
		return nil, err
	}

	errors, err := s.stats.GetErrorsPerHour(ctx, org)
	if err != nil {
		return nil, err
	}

	activity, err := s.stats.GetActivityByDay(ctx, org)
	if err != nil {
		return nil, err
	}

	return &statsdomain.GraphStats{
		Errors:   errors,
		Activity: activity,
	}, nil
}
