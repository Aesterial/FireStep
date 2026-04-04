package handlers

import (
	"context"

	statspb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/stats"
	statsservice "github.com/aesterial/fire-step/backend/internal/app/stats"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/protobuf/types/known/emptypb"
)

type StatsHandler struct {
	statspb.UnimplementedStatsServiceServer
	auth  *Authentificator
	stats *statsservice.Service
}

func NewStatsHandler(stats *statsservice.Service, auth *Authentificator) *StatsHandler {
	return &StatsHandler{
		auth:  auth,
		stats: stats,
	}
}

func (s *StatsHandler) TitleStats(ctx context.Context, _ *emptypb.Empty) (*statspb.Stats, error) {
	auth, err := s.auth.User(ctx, true)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	stats, err := s.stats.GetTitleStats(ctx, *auth.UserID)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	return stats.Protobuf(), nil
}

func (s *StatsHandler) GraphStats(ctx context.Context, _ *emptypb.Empty) (*statspb.GraphStatsResponse, error) {
	auth, err := s.auth.User(ctx, true)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	stats, err := s.stats.GetGraphStats(ctx, *auth.UserID)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	return stats.Protobuf(), nil
}
