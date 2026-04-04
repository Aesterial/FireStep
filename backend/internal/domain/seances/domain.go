package seancesdomain

import (
	"encoding/json"
	"time"

	seancespb "github.com/aesterial/fire-step/backend/internal/api/xyz/fire-step/v1/seances"
	userdomain "github.com/aesterial/fire-step/backend/internal/domain/user"
	"google.golang.org/protobuf/types/known/timestamppb"
)

type Action struct {
	ID     int32
	Action string
	At     time.Time
}

func (a *Action) Protobuf() *seancespb.Action {
	if a == nil {
		return nil
	}
	return &seancespb.Action{
		Id:     a.ID,
		Action: a.Action,
		At:     timestamppb.New(a.At),
	}
}

type Actions []*Action

func (a *Actions) Protobuf() []*seancespb.Action {
	if a == nil {
		return nil
	}
	var list = make([]*seancespb.Action, len(*a))
	for i, e := range *a {
		list[i] = e.Protobuf()
	}
	return list
}

func ActionsFromProto(acts []*seancespb.Action) Actions {
	if len(acts) == 0 {
		return nil
	}
	var list = make(Actions, len(acts))
	for i, e := range acts {
		list[i] = &Action{
			ID:     e.Id,
			Action: e.Action,
			At:     e.At.AsTime(),
		}
	}
	return list
}

type Seance struct {
	ID      userdomain.UUID
	Owner   userdomain.UUID
	Errors  int32
	Actions Actions
	At      time.Time
	Done    time.Time
}

func (s *Seance) Protobuf() *seancespb.Seance {
	if s == nil {
		return nil
	}
	actions, err := json.Marshal(s.Actions)
	if err != nil {
		return nil
	}
	return &seancespb.Seance{
		Id:          s.ID.String(),
		OwnerId:     s.Owner.String(),
		Errors:      s.Errors,
		ActionsJson: string(actions),
		At:          timestamppb.New(s.At),
		Done:        timestamppb.New(s.Done),
	}
}

type Seances []*Seance

func (s *Seances) Protobuf() *seancespb.Seances {
	if s == nil {
		return nil
	}
	var resp = make([]*seancespb.Seance, len(*s))
	for i, e := range *s {
		resp[i] = e.Protobuf()
	}
	return &seancespb.Seances{List: resp}
}
