package handlers

import (
	"context"

	loginpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/login"
	userpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/user"
	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	loginservice "github.com/aesterial/fire-step/backend/internal/app/login"
	sessionservice "github.com/aesterial/fire-step/backend/internal/app/sessions"
	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/types/known/emptypb"
)

type LoginHandler struct {
	loginpb.UnimplementedLoginServiceServer
	auth *Authentificator
	lgn  *loginservice.Service
	ses  *sessionservice.Service
}

func NewLoginHandler(lgn *loginservice.Service, ses *sessionservice.Service, auth *Authentificator) *LoginHandler {
	return &LoginHandler{lgn: lgn, ses: ses, auth: auth}
}

func (l *LoginHandler) Register(ctx context.Context, req *loginpb.RegisterRequest) (*userpb.User, error) {
	device, err := DeviceFromContext(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	usr, sessionID, err := l.lgn.Register(ctx, req.GetUsername(), req.GetEmail(), req.GetInitials(), req.GetPassword(), req.GetOrg(), device)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	if err := l.setAuthHeaders(ctx, *sessionID, device); err != nil {
		return nil, apperrors.Wrap(err)
	}
	return usr.Protobuf(), nil
}

func (l *LoginHandler) Login(ctx context.Context, req *loginpb.LoginRequest) (*userpb.User, error) {
	device, err := DeviceFromContext(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	usr, sessionID, err := l.lgn.Login(ctx, req.GetUsername(), req.GetPassword(), device)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	if err := l.setAuthHeaders(ctx, *sessionID, device); err != nil {
		return nil, apperrors.Wrap(err)
	}
	return usr.Protobuf(), nil
}

func (l *LoginHandler) Logout(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	meta, err := l.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	if err := l.lgn.Logout(ctx, *meta.SessionID); err != nil {
		return nil, apperrors.Wrap(err)
	}
	return &emptypb.Empty{}, nil
}

func (l *LoginHandler) Device(ctx context.Context, _ *emptypb.Empty) (*loginpb.DeviceLoginResponse, error) {
	meta, err := l.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}
	session, err := l.ses.Create(ctx, *meta.UserID, sessiondomain.Client)
	if err != nil {
		loggingservice.Error("login_handler", "failed to create session for client", loggingservice.FD("error", err))
		return nil, apperrors.Wrap(err)
	}
	return &loginpb.DeviceLoginResponse{Session: session.ID.String()}, nil
}

func (l *LoginHandler) setAuthHeaders(ctx context.Context, sessionID interface{ String() string }, device sessiondomain.DeviceType) error {
	return grpc.SetHeader(ctx, metadata.Pairs(
		sessionMetadataKey, sessionMetadataPrefix+sessionID.String(),
		deviceMetadataKey, device.String(),
	))
}
