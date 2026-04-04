package repositories

import (
	"context"
	"errors"
	"strings"
	"time"

	sessiondomain "github.com/aesterial/fire-step/backend/internal/domain/session"
	"github.com/aesterial/fire-step/backend/internal/domain/user"
	"github.com/aesterial/fire-step/backend/internal/infra/db/sqlc"
	apperrors "github.com/aesterial/fire-step/backend/internal/shared/errors"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type SessionRepository struct {
	conn sqlc.Querier
}

func NewSessionRepository(conn sqlc.Querier) *SessionRepository {
	return &SessionRepository{conn: conn}
}

var _ sessiondomain.Repository = (*SessionRepository)(nil)

func (s *SessionRepository) parseSession(session sqlc.Session) *sessiondomain.Session {
	return &sessiondomain.Session{
		ID:        userdomain.ParseUUIDBytes(session.ID.Bytes),
		OwnerID:   userdomain.ParseUUIDBytes(session.Owner.Bytes),
		Device:    sessiondomain.DeviceType(strings.ToLower(string(session.Device))),
		CreatedAt: session.Createdat.Time,
		ExpiresAt: session.Expiresat.Time,
		LastSeen:  session.Lastseenat.Time,
	}
}

func (s *SessionRepository) Create(ctx context.Context, owner userdomain.UUID, deviceType sessiondomain.DeviceType) (*sessiondomain.Session, error) {
	if !deviceType.IsValid() {
		return nil, apperrors.InvalidArguments
	}
	result, err := s.conn.CreateSession(ctx, sqlc.CreateSessionParams{
		Owner:  owner.PGType(),
		Device: sqlc.DeviceType(deviceType.String()),
	})
	if err != nil {
		return nil, err
	}
	return s.parseSession(result), nil
}

func (s *SessionRepository) List(ctx context.Context, owner userdomain.UUID) (sessiondomain.Sessions, error) {
	list, err := s.conn.SessionList(ctx, owner.PGType())
	if err != nil {
		return nil, err
	}
	var resp = make(sessiondomain.Sessions, len(list))
	for i, e := range list {
		resp[i] = s.parseSession(e)
	}
	return resp, nil
}

func (s *SessionRepository) IsValid(ctx context.Context, sessionID userdomain.UUID, deviceType sessiondomain.DeviceType) (bool, error) {
	info, err := s.conn.GetSession(ctx, sessionID.PGType())
	if err != nil {
		return false, err
	}
	if sessiondomain.ParseDeviceType(string(info.Device)).String() != deviceType.String() {
		return false, apperrors.ParamsNotMatch
	}
	if !info.Expiresat.Time.After(time.Now()) {
		return false, nil
	}
	return true, nil
}

func (s *SessionRepository) IsExists(ctx context.Context, id userdomain.UUID) (bool, error) {
	exists, err := s.conn.IsSessionExists(ctx, id.PGType())
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return false, nil
		}
		return false, err
	}
	return exists, nil
}

func (s *SessionRepository) Revoke(ctx context.Context, id userdomain.UUID) error {
	exists, err := s.IsExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return apperrors.RecordNotFound
	}
	return s.conn.RevokeSession(ctx, id.PGType())
}

func (s *SessionRepository) LastSeen(ctx context.Context, id userdomain.UUID) error {
	exists, err := s.IsExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return apperrors.RecordNotFound
	}
	return s.conn.SetSessionLastSeen(ctx, sqlc.SetSessionLastSeenParams{
		Lastseenat: pgtype.Timestamptz{
			Time:             time.Now(),
			InfinityModifier: 0,
			Valid:            true,
		},
		ID: id.PGType(),
	})
}

func (s *SessionRepository) GetOwner(ctx context.Context, id userdomain.UUID) (*userdomain.UUID, error) {
	exists, err := s.IsExists(ctx, id)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, apperrors.RecordNotFound
	}
	owner, err := s.conn.SessionOwner(ctx, id.PGType())
	if err != nil {
		return nil, err
	}
	return new(userdomain.ParseUUIDBytes(owner.Bytes)), nil
}
