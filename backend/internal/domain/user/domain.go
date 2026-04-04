package userdomain

import (
	"time"

	userpb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/user"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type UUID struct {
	uuid.UUID
}

func (u UUID) PGType() pgtype.UUID {
	return pgtype.UUID{Bytes: u.UUID, Valid: true}
}

func ParseUUIDSTR(str string) (UUID, error) {
	id, err := uuid.Parse(str)
	if err != nil {
		return UUID{}, err
	}
	return UUID{id}, nil
}

func ParseUUIDBytes(bytes [16]byte) UUID {
	return UUID{bytes}
}

type User struct {
	ID           UUID
	Username     string
	Initials     string
	Email        string
	Organization string
	AdminAccess  bool
	Joined       time.Time
}

type Users []*User

func (u *User) Protobuf() *userpb.User {
	if u == nil {
		return nil
	}

	return &userpb.User{
		Id:       u.ID.String(),
		Username: u.Username,
		Initials: u.Initials,
		Email:    u.Email,
		Org:      u.Organization,
		Joined:   timestamppb.New(u.Joined),
	}
}

func (u *Users) Protobuf() *userpb.Users {
	if u == nil {
		return nil
	}

	list := make([]*userpb.User, len(*u))
	for i, e := range *u {
		list[i] = e.Protobuf()
	}
	return &userpb.Users{List: list}
}
