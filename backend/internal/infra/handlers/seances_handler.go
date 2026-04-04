package handlers

import (
	"context"

	seancespb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/seances"
	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	seanceservice "github.com/aesterial/fire-step/backend/internal/app/seance"
	seancesdomain "github.com/aesterial/fire-step/backend/internal/domain/seances"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/protobuf/types/known/emptypb"
)

type SeanceHandler struct {
	seancespb.UnimplementedSeancesServiceServer
	auth *Authentificator
	sean *seanceservice.Service
}

func NewSeanceHandler(sean *seanceservice.Service, auth *Authentificator) *SeanceHandler {
	return &SeanceHandler{
		auth: auth,
		sean: sean,
	}
}

func (s *SeanceHandler) List(ctx context.Context, _ *emptypb.Empty) (*seancespb.Seances, error) {
	auth, err := s.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	list, err := s.sean.GetList(ctx, *auth.UserID)
	if err != nil {
		loggingservice.Info("seance_handler", "failed to get list of seances", loggingservice.FD("error", err))
		return nil, apperrors.Wrap(err)
	}
	return list.Protobuf(), nil
}

func (s *SeanceHandler) Create(ctx context.Context, req *seancespb.CreateSeanceRequest) (*seancespb.Seance, error) {
	auth, err := s.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	seance, err := s.sean.Create(ctx, *auth.UserID, req.GetErrors(), seancesdomain.ActionsFromProto(req.GetActions()), req.GetAt().AsTime(), req.GetDone().AsTime())
	if err != nil {
		loggingservice.Error("seance_handler", "failed to create seance", loggingservice.FD("error", err))
		return nil, apperrors.Wrap(err)
	}
	return seance.Protobuf(), nil
}
