package handlers

import (
	"context"

	sessionpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/session"
	sessionservice "github.com/aesterial/fire-step/backend/internal/app/sessions"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/protobuf/types/known/emptypb"
)

type SessionsHandler struct {
	sessionpb.UnimplementedSessionsServiceServer
	auth *Authentificator
	ses  *sessionservice.Service
}

func NewSessionsHandler(ses *sessionservice.Service, auth *Authentificator) *SessionsHandler {
	return &SessionsHandler{ses: ses, auth: auth}
}

func (s *SessionsHandler) List(ctx context.Context, _ *emptypb.Empty) (*sessionpb.Sessions, error) {
	usr, err := s.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	list, err := s.ses.List(ctx, *usr.UserID)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	return list.Protobuf(), nil
}

func (s *SessionsHandler) Revoke(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	meta, err := s.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	if err := s.ses.Revoke(ctx, *meta.SessionID); err != nil {
		return nil, apperrors.Wrap(err)
	}

	return &emptypb.Empty{}, nil
}
