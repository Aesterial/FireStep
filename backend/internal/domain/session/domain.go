package sessiondomain

import (
	"strings"
	"time"

	sessionspb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/session"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type DeviceType string

const (
	Web    DeviceType = "web"
	Client DeviceType = "client"
)

func ParseDeviceType(str string) DeviceType {
	switch strings.TrimSpace(strings.ToLower(str)) {
	case Web.String():
		return Web
	case Client.String():
		return Client
	default:
		return Client
	}
}

func (d DeviceType) IsValid() bool {
	switch d {
	case Web, Client:
		return true
	default:
		return false
	}
}

func (d DeviceType) String() string {
	return string(d)
}

func (d DeviceType) Protobuf() sessionspb.DeviceType {
	if !d.IsValid() {
		return sessionspb.DeviceType_UNSPECIFIED
	}
	switch d {
	case Client:
		return sessionspb.DeviceType_CLIENT
	case Web:
		return sessionspb.DeviceType_WEB
	default:
		return sessionspb.DeviceType_UNSPECIFIED
	}
}

type Session struct {
	ID        userdomain.UUID
	OwnerID   userdomain.UUID
	Device    DeviceType
	CreatedAt time.Time
	ExpiresAt time.Time
	LastSeen  time.Time
}

func (s *Session) Protobuf() *sessionspb.Session {
	if s == nil {
		return nil
	}
	return &sessionspb.Session{
		Id:         s.ID.String(),
		OwnerId:    s.OwnerID.String(),
		Device:     s.Device.Protobuf(),
		CreatedAt:  timestamppb.New(s.CreatedAt),
		ExpiresAt:  timestamppb.New(s.ExpiresAt),
		LastSeenAt: timestamppb.New(s.LastSeen),
	}
}

type Sessions []*Session

func (s *Sessions) Protobuf() *sessionspb.Sessions {
	if s == nil {
		return nil
	}

	var list = make([]*sessionspb.Session, len(*s))
	for i, e := range *s {
		list[i] = e.Protobuf()
	}
	return &sessionspb.Sessions{List: list}
}
