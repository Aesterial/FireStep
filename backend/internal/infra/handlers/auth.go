package handlers

import (
	"context"
	"strings"

	loggingservice "github.com/aesterial/fire-step/backend/internal/app/logging"
	sessionservice "github.com/aesterial/fire-step/backend/internal/app/sessions"
	userservice "github.com/aesterial/fire-step/backend/internal/app/user"
	metadatadomain "github.com/aesterial/fire-step/backend/internal/domain/metadata"
	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"google.golang.org/grpc/metadata"
)

const (
	sessionMetadataKey    = "aesterial_firestep_session"
	sessionMetadataPrefix = "FS-"
	deviceMetadataKey     = "device"
)

type Authentificator struct {
	ses *sessionservice.Service
	usr *userservice.Service
}

func NewAuthentificator(ses *sessionservice.Service, usr *userservice.Service) *Authentificator {
	return &Authentificator{ses: ses, usr: usr}
}

func (a *Authentificator) idFromContext(ctx context.Context) (*userdomain.UUID, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, apperrors.InvalidArguments
	}

	for _, value := range md.Get(sessionMetadataKey) {
		sessionID, ok := strings.CutPrefix(value, sessionMetadataPrefix)
		if !ok || sessionID == "" {
			continue
		}
		id, err := userdomain.ParseUUIDSTR(sessionID)
		if err != nil {
			return nil, err
		}
		return &id, nil
	}

	return nil, apperrors.InvalidArguments
}

func DeviceFromContext(ctx context.Context) (sessiondomain.DeviceType, error) {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return "", apperrors.InvalidArguments
	}

	for _, value := range md.Get(deviceMetadataKey) {
		if value == "" {
			continue
		}
		return sessiondomain.ParseDeviceType(value), nil
	}
	loggingservice.Warning("", "no valid device found")
	return "", apperrors.InvalidArguments
}

func (a *Authentificator) User(ctx context.Context, checkStaff ...bool) (*metadatadomain.Metadata, error) {
	var staffCheck bool
	if len(checkStaff) > 0 {
		staffCheck = checkStaff[0]
	}
	var meta metadatadomain.Metadata
	var err error
	meta.DeviceType, err = DeviceFromContext(ctx)
	if err != nil {
		return &meta, err
	}
	meta.SessionID, err = a.idFromContext(ctx)
	if err != nil {
		return &meta, err
	}
	valid, err := a.ses.IsValid(ctx, *meta.SessionID, meta.DeviceType)
	if err != nil {
		return &meta, err
	}
	if !valid {
		return &meta, apperrors.Unauthenticated
	}
	if err := a.ses.SetLastSeen(ctx, *meta.SessionID); err != nil {
		return nil, apperrors.Wrap(err)
	}
	owner, err := a.ses.GetOwner(ctx, *meta.SessionID)
	if err != nil {
		return &meta, err
	}
	if owner == nil {
		return nil, apperrors.RecordNotFound
	}
	if staffCheck {
		staff, err := a.usr.IsAdmin(ctx, *owner)
		if err != nil {
			loggingservice.Error("auth", "failed to check is user admin: "+err.Error())
			return nil, apperrors.Wrap(err)
		}
		if !staff {
			return nil, apperrors.AccessDenied
		}
	}
	meta.UserID = owner
	return &meta, nil
}
