package handlers

import (
	"context"

	firestepv1 "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1"
	userpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/user"
	userservice "github.com/aesterial/fire-step/backend/internal/app/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/protobuf/types/known/emptypb"
)

type UserHandler struct {
	userpb.UnimplementedUserServiceServer
	auth *Authentificator
	usr  *userservice.Service
}

func NewUserHandler(usr *userservice.Service, auth *Authentificator) *UserHandler {
	return &UserHandler{usr: usr, auth: auth}
}

func (u *UserHandler) Info(ctx context.Context, _ *emptypb.Empty) (*userpb.User, error) {
	meta, err := u.auth.User(ctx)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	usr, err := u.usr.Info(ctx, *meta.UserID)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	return usr.Protobuf(), nil
}

func (u *UserHandler) List(ctx context.Context, req *firestepv1.RequestWithTextValue) (*userpb.Users, error) {
	meta, err := u.auth.User(ctx, true)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	currentUser, err := u.usr.Info(ctx, *meta.UserID)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	org := currentUser.Organization
	if req != nil && req.GetValue() != "" {
		org = req.GetValue()
	}

	users, err := u.usr.List(ctx, org)
	if err != nil {
		return nil, apperrors.Wrap(err)
	}

	return users.Protobuf(), nil
}
